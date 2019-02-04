# frozen_string_literal: true

require 'fileutils'
require 'open3'

module Gitlab
  module Popen
    extend self

    Result = Struct.new(:cmd, :stdout, :stderr, :status, :duration)

    # Returns [stdout + stderr, status]
    def popen(cmd, path = nil, vars = {}, &block)
      result = popen_with_detail(cmd, path, vars, &block)

      ["#{result.stdout}#{result.stderr}", result.status&.exitstatus]
    end

    # Returns Result
    def popen_with_detail(cmd, path = nil, vars = {})
      unless cmd.is_a?(Array)
        raise "System commands must be given as an array of strings"
      end

      path ||= Dir.pwd
      vars['PWD'] = path
      options = { chdir: path }

      unless File.directory?(path)
        FileUtils.mkdir_p(path)
      end

      cmd_stdout = ''
      cmd_stderr = ''
      cmd_status = nil
      start = Time.now

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

      Result.new(cmd, cmd_stdout, cmd_stderr, cmd_status, Time.now - start)
    end
  end
end
