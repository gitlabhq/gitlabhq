# Gitaly note: JV: looks like this is only used by Gitlab::Git::HooksService in
# app/services. We shouldn't bother migrating this until we know how
# Gitlab::Git::HooksService will be migrated.

module Gitlab
  module Git
    class Hook
      GL_PROTOCOL = 'web'.freeze
      attr_reader :name, :path, :repository

      def initialize(name, repository)
        @name = name
        @repository = repository
        @path = File.join(repo_path.strip, 'hooks', name)
      end

      def repo_path
        repository.path
      end

      def exists?
        File.exist?(path)
      end

      def trigger(gl_id, gl_username, oldrev, newrev, ref)
        return [true, nil] unless exists?

        Bundler.with_clean_env do
          case name
          when "pre-receive", "post-receive"
            call_receive_hook(gl_id, gl_username, oldrev, newrev, ref)
          when "update"
            call_update_hook(gl_id, gl_username, oldrev, newrev, ref)
          end
        end
      end

      private

      def call_receive_hook(gl_id, gl_username, oldrev, newrev, ref)
        changes = [oldrev, newrev, ref].join(" ")

        exit_status = false
        exit_message = nil

        vars = {
          'GL_ID' => gl_id,
          'GL_USERNAME' => gl_username,
          'PWD' => repo_path,
          'GL_PROTOCOL' => GL_PROTOCOL,
          'GL_REPOSITORY' => repository.gl_repository
        }

        options = {
          chdir: repo_path
        }

        Open3.popen3(vars, path, options) do |stdin, stdout, stderr, wait_thr|
          exit_status = true
          stdin.sync = true

          # in git, pre- and post- receive hooks may just exit without
          # reading stdin. We catch the exception to avoid a broken pipe
          # warning
          begin
            # inject all the changes as stdin to the hook
            changes.lines do |line|
              stdin.puts line
            end
          rescue Errno::EPIPE
          end

          stdin.close

          unless wait_thr.value == 0
            exit_status = false
            exit_message = retrieve_error_message(stderr, stdout)
          end
        end

        [exit_status, exit_message]
      end

      def call_update_hook(gl_id, gl_username, oldrev, newrev, ref)
        env = {
          'GL_ID' => gl_id,
          'GL_USERNAME' => gl_username,
          'PWD' => repo_path
        }

        options = {
          chdir: repo_path
        }

        args = [ref, oldrev, newrev]

        stdout, stderr, status = Open3.capture3(env, path, *args, options)
        [status.success?, Gitlab::Utils.nlbr(stderr.presence || stdout)]
      end

      def retrieve_error_message(stderr, stdout)
        err_message = stderr.read
        err_message = err_message.blank? ? stdout.read : err_message
        Gitlab::Utils.nlbr(err_message)
      end
    end
  end
end
