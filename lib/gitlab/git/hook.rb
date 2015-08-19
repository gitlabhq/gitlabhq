module Gitlab
  module Git
    class Hook
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
        return true unless exists?

        changes = [oldrev, newrev, ref].join(" ")

        # function  will return true if succesful
        exit_status = false

        vars = {
          'GL_ID' => gl_id,
          'PWD' => repo_path
        }

        options = {
          chdir: repo_path
        }

        Open3.popen2(vars, path, options) do |stdin, _, wait_thr|
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
          end
        end

        exit_status
      end
    end
  end
end
