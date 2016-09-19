module Gitlab
  module Git
    class Hook
      GL_PROTOCOL = 'web'.freeze
      attr_reader :name, :repo_path, :path

      def initialize(name, repo_path)
        @name = name
        @repo_path = repo_path
        @path = File.join(repo_path.strip, 'hooks', name)
      end

      def exists?
        File.exist?(path)
      end

      def trigger(gl_id, oldrev, newrev, ref)
        return [true, nil] unless exists?

        Bundler.with_clean_env do
          case name
          when "pre-receive", "post-receive"
            call_receive_hook(gl_id, oldrev, newrev, ref)
          when "update"
            call_update_hook(gl_id, oldrev, newrev, ref)
          end
        end
      end

      private

      def call_receive_hook(gl_id, oldrev, newrev, ref)
        changes = [oldrev, newrev, ref].join(" ")

        exit_status = false
        exit_message = nil

        vars = {
          'GL_ID' => gl_id,
          'PWD' => repo_path,
          'GL_PROTOCOL' => GL_PROTOCOL
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

      def call_update_hook(gl_id, oldrev, newrev, ref)
        Dir.chdir(repo_path) do
          stdout, stderr, status = Open3.capture3({ 'GL_ID' => gl_id }, path, ref, oldrev, newrev)
          [status.success?, stderr.presence || stdout]
        end
      end

      def retrieve_error_message(stderr, stdout)
        err_message = stderr.gets
        err_message.blank? ? stdout.gets : err_message
      end
    end
  end
end
