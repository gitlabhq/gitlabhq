module Gitlab
  module Utils
    extend self

    # Run system command without outputting to stdout.
    #
    # @param  cmd [Array<String>]
    # @return [Integer] exit status
    def system_silent(cmd)
      IO.popen(cmd).close
      $?.exitstatus
    end
  end
end
