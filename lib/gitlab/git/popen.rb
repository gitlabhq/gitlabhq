# Gitaly note: JV: no RPC's here.

require 'open3'

module Gitlab
  module Git
    module Popen
      FAST_GIT_PROCESS_TIMEOUT = 15.seconds

      def popen(cmd, path, vars = {}, lazy_block: nil)
        unless cmd.is_a?(Array)
          raise "System commands must be given as an array of strings"
        end

        path ||= Dir.pwd
        vars['PWD'] = path
        options = { chdir: path }

        cmd_output = ""
        cmd_status = 0
        Open3.popen3(vars, *cmd, options) do |stdin, stdout, stderr, wait_thr|
          stdout.set_encoding(Encoding::ASCII_8BIT)

          yield(stdin) if block_given?
          stdin.close

          if lazy_block
            return [lazy_block.call(stdout.lazy), 0]
          else
            cmd_output << stdout.read
          end

          cmd_output << stderr.read
          cmd_status = wait_thr.value.exitstatus
        end

        [cmd_output, cmd_status]
      end

      def popen_with_timeout(cmd, timeout, path, vars = {})
        unless cmd.is_a?(Array)
          raise "System commands must be given as an array of strings"
        end

        path ||= Dir.pwd
        vars['PWD'] = path

        unless File.directory?(path)
          FileUtils.mkdir_p(path)
        end

        rout, wout = IO.pipe
        rerr, werr = IO.pipe

        pid = Process.spawn(vars, *cmd, out: wout, err: werr, chdir: path, pgroup: true)

        begin
          status = process_wait_with_timeout(pid, timeout)

          # close write ends so we could read them
          wout.close
          werr.close

          cmd_output = rout.readlines.join
          cmd_output << rerr.readlines.join # Copying the behaviour of `popen` which merges stderr into output

          [cmd_output, status.exitstatus]
        rescue Timeout::Error => e
          kill_process_group_for_pid(pid)

          raise e
        ensure
          wout.close unless wout.closed?
          werr.close unless werr.closed?

          rout.close
          rerr.close
        end
      end

      def process_wait_with_timeout(pid, timeout)
        deadline = timeout.seconds.from_now
        wait_time = 0.01

        while deadline > Time.now
          sleep(wait_time)
          _, status = Process.wait2(pid, Process::WNOHANG)

          return status unless status.nil?
        end

        raise Timeout::Error, "Timeout waiting for process ##{pid}"
      end

      def kill_process_group_for_pid(pid)
        Process.kill("KILL", -pid)
        Process.wait(pid)
      rescue Errno::ESRCH
      end
    end
  end
end
