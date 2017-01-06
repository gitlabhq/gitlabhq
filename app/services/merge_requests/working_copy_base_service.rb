module MergeRequests
  class WorkingCopyBaseService < MergeRequests::BaseService
    class GitCommandError < StandardError; end

    include Gitlab::Popen

    attr_reader :merge_request

    def run_git_command(command, path, env, message = nil, &block)
      git_command = [Gitlab.config.git.bin_path] + command
      output, status = popen(git_command, path, env, &block)

      unless status.zero?
        log_error("Failed to #{message}:") if message
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
      Gitlab::GitLogger.error(message)
    end

    def clean_dir
      FileUtils.rm_rf(tree_path) if File.exist?(tree_path)
    end

    def git_env
      { 'GL_ID' => Gitlab::GlId.gl_id(current_user), 'GL_PROTOCOL' => 'web' }
    end

    # Don't try to print expensive instance variables.
    def inspect
      "#<#{self.class} #{merge_request.to_reference(full: true)}>"
    end
  end
end
