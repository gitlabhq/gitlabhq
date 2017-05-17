module Gitlab
  module Git
    module Storage
      module ForkedStorageCheck
        extend self

        def storage_available?(path, timeout_seconds = 5)
          status = timeout_check(path, timeout_seconds)

          status.success?
        end

        def timeout_check(path, timeout_seconds)
          filesystem_check_pid = check_filesystem_in_fork(path)

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

        # This call forks out into a process, that process will then be replaced
        # With an `exec` call, since we fork out into a shell, we can create a
        # child process without needing an ActiveRecord-connection.
        #
        # Inside the shell, we use `& wait` to fork another child. We do this
        # to prevent leaving a zombie process when the parent gets killed by the
        # timeout.
        #
        # https://stackoverflow.com/questions/27892975/what-causes-activerecord-breaking-postgres-connection-after-forking
        # https://stackoverflow.com/questions/22012943/activerecordstatementinvalid-runtimeerror-the-connection-cannot-be-reused-in
        def check_filesystem_in_fork(path)
          fork do
            STDOUT.reopen('/dev/null')
            STDERR.reopen('/dev/null')

            exec("(#{test_script(path)}) & wait %1")
          end
        end

        def test_script(path)
          "testpath=\"$(realpath #{Shellwords.escape(path)})\" && stat $testpath"
        end
      end
    end
  end
end
