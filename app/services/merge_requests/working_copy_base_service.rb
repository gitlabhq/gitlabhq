module MergeRequests
  class WorkingCopyBaseService < MergeRequests::BaseService
    GitCommandError = Class.new(StandardError)

    include Gitlab::Popen

    attr_reader :merge_request

    def git_command(command)
      [Gitlab.config.git.bin_path] + command
    end

    def run_git_command(command, path, env, message = nil, &block)
      run_command(git_command(command), path, env, message, &block)
    end

    def run_command(command, path, env, message = nil, &block)
      output, status = popen(command, path, env, &block)

      unless status.zero?
        if message
          log_error("Failed to #{message} with `#{command.join(' ')}`:")
        else
          log_error("`#{command.join(' ')}` failed:")
        end

        log_error(output)

        raise GitCommandError
      end

      output.chomp
    end

    def source_project
      @source_project ||= merge_request.source_project
    end

    def target_project
      @target_project ||= merge_request.target_project
    end

    def log_error(message)
      Gitlab::GitLogger.error("#{self.class.name} error (#{merge_request.to_reference(full: true)}): #{message}")
    end

    def clean_dir
      FileUtils.rm_rf(tree_path) if File.exist?(tree_path)
    end

    def git_env
      {
        'GL_ID' => Gitlab::GlId.gl_id(current_user),
        'GL_PROTOCOL' => 'web',
        'GL_REPOSITORY' => Gitlab::GlRepository.gl_repository(project, false)
      }
    end

    # Don't try to print expensive instance variables.
    def inspect
      "#<#{self.class} #{merge_request.to_reference(full: true)}>"
    end
  end
end
