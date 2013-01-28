module Gitlab
  module Popen
    def popen(cmd, path)
      vars = { "PWD" => path }
      options = { :chdir => path }

      @cmd_output = ""
      @cmd_status = 0
      Open3.popen3(vars, cmd, options) do |stdin, stdout, stderr, wait_thr|
        @cmd_status = wait_thr.value.exitstatus
        @cmd_output << stdout.read
        @cmd_output << stderr.read
      end

      return @cmd_output, @cmd_status
    end
  end
end
