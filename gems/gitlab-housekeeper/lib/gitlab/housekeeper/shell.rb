# frozen_string_literal: true

require 'open3'

module Gitlab
  module Housekeeper
    class Shell
      Error = Class.new(StandardError)

      def self.execute(*cmd)
        stdin, stdout, stderr, wait_thr = Open3.popen3(*cmd)

        stdin.close
        out = stdout.read
        stdout.close
        err = stderr.read
        stderr.close

        exit_status = wait_thr.value

        raise Error, "Failed with #{exit_status}\n#{out}\n#{err}\n" unless exit_status.success?

        out + err
      end
    end
  end
end
