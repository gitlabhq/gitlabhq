# frozen_string_literal: true

require 'fileutils'
require 'open3'

module Gitlab
  module Popen
    extend self

    Result = Struct.new(:cmd, :stdout, :stderr, :status, :duration)

    # Returns [stdout + stderr, status]
    # status is either the exit code or the signal that killed the process
    def popen(cmd, path = nil, vars = {}, &block)
      result = popen_with_detail(cmd, path, vars, &block)

      # Process#waitpid returns Process::Status, which holds a 16-bit value.
      # The higher-order 8 bits hold the exit() code (`exitstatus`).
      # The lower-order bits holds whether the process was terminated.
      # If the process didn't exit normally, `exitstatus` will be `nil`,
      # but we still want a non-zero code, even if the value is
      # platform-dependent.
      status = result.status&.exitstatus || result.status.to_i

      ["#{result.stdout}#{result.stderr}", status]
    end

    def popen_with_streaming(cmd, path = nil, vars = {}, &block)
      vars, options = prepare_popen_command(cmd, path, vars)

      cmd_status = nil
      block_mutex = Mutex.new if block

      Open3.popen3(vars, *cmd, options) do |stdin, stdout, stderr, wait_thr|
        stdin.close # Close stdin immediately since we're not using it for streaming

        stdout_thread = read_stream_in_thread(stdout, :stdout, block_mutex, &block)
        stderr_thread = read_stream_in_thread(stderr, :stderr, block_mutex, &block)

        stdout_thread.join
        stderr_thread.join

        cmd_status = wait_thr.value&.exitstatus || wait_thr.value.to_i
      end

      cmd_status
    end

    def popen_with_detail(cmd, path = nil, vars = {})
      vars, options = prepare_popen_command(cmd, path, vars)

      cmd_stdout = ''
      cmd_stderr = ''
      cmd_status = nil
      start = Time.now.to_f

      Open3.popen3(vars, *cmd, options) do |stdin, stdout, stderr, wait_thr|
        # stderr and stdout pipes can block if stderr/stdout aren't drained: https://bugs.ruby-lang.org/issues/9082
        # Mimic what Ruby does with capture3: https://github.com/ruby/ruby/blob/1ec544695fa02d714180ef9c34e755027b6a2103/lib/open3.rb#L257-L273
        out_reader = Thread.new { stdout.read }
        err_reader = Thread.new { stderr.read }

        yield(stdin) if block_given?
        stdin.close

        cmd_stdout = out_reader.value
        cmd_stderr = err_reader.value
        cmd_status = wait_thr.value
      end

      Result.new(cmd, cmd_stdout, cmd_stderr, cmd_status, Time.now.to_f - start)
    end

    private

    def prepare_popen_command(cmd, path, vars)
      raise "Commands must be given as an array of strings" unless cmd.is_a?(Array)
      raise "Commands must be split into an array of space-separated values" if cmd.one? && cmd.first.match?(/\s/)

      path ||= Dir.pwd
      vars['PWD'] = path
      options = { chdir: path }

      FileUtils.mkdir_p(path) unless File.directory?(path)

      [vars, options]
    end

    def read_stream_in_thread(stream, stream_type, mutex, &block)
      Thread.new do
        stream.each_line do |line|
          mutex.synchronize { yield(stream_type, line) } if block
        end
      rescue IOError
        # This is expected when the process exits and closes its streams. No action needed.
      end
    end
  end
end
