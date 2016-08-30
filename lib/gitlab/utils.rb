module Gitlab
  module Utils
    extend self

    # Run system command without outputting to stdout.
    #
    # @param  cmd [Array<String>]
    # @return [Boolean]
    def system_silent(cmd)
      Popen.popen(cmd).last.zero?
    end

    def force_utf8(str)
      str.force_encoding(Encoding::UTF_8)
    end
  end
end
