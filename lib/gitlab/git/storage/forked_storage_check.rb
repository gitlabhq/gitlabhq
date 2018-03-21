module Gitlab
  module Git
    module Storage
      module ForkedStorageCheck
        extend self

        def storage_available?(path, timeout_seconds = 5, retries = 1)
          partial_timeout = timeout_seconds / retries
          status = timeout_check(path, partial_timeout)

          # If the status check did not succeed the first time, we retry a few
          # more times to avoid one-off failures
          current_attempts = 1
          while current_attempts < retries && !status.success?
            status = timeout_check(path, partial_timeout)
            current_attempts += 1
          end

          status.success?
        end

        def timeout_check(path, timeout_seconds)
          filesystem_check_pid = check_filesystem_in_process(path)

          deadline = timeout_seconds.seconds.from_now.utc
          wait_time = 0.01
          status = nil

          while status.nil?

            if deadline > Time.now.utc
              sleep(wait_time)
              _pid, status = Process.wait2(filesystem_check_pid, Process::WNOHANG)
            else
              Process.kill('KILL', filesystem_check_pid)
              # Blocking wait, so we are sure the process is gone before continuing
              _pid, status = Process.wait2(filesystem_check_pid)
            end
          end

          status
        end

        # This will spawn a new 2 processes to do the check:
        # The outer child (waiter) will spawn another child process (stater).
        #
        # The stater is the process is performing the actual filesystem check
        # the check might hang if the filesystem is acting up.
        # In this case we will send a `KILL` to the waiter, which will still
        # be responsive while the stater is hanging.
        def check_filesystem_in_process(path)
          spawn('ruby', '-e', ruby_check, path, [:out, :err] => '/dev/null')
        end

        def ruby_check
          <<~RUBY_FILESYSTEM_CHECK
          inner_pid = fork { File.stat(ARGV.first) }
          Process.waitpid(inner_pid)
          exit $?.exitstatus
          RUBY_FILESYSTEM_CHECK
        end
      end
    end
  end
end
