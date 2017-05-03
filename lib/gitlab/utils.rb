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

    def to_boolean(value)
      return value if [true, false].include?(value)
      return true if value =~ /^(true|t|yes|y|1|on)$/i
      return false if value =~ /^(false|f|no|n|0|off)$/i

      nil
    end

    def try_megabytes_to_bytes(size)
      Integer(size).megabytes
    rescue ArgumentError
      size
    end

    # See: http://stackoverflow.com/questions/2108727/which-in-ruby-checking-if-program-exists-in-path-from-ruby
    # Cross-platform way of finding an executable in the $PATH.
    #
    #   which('ruby') #=> /usr/bin/ruby
    def which(cmd, env = ENV)
      exts = env['PATHEXT'] ? env['PATHEXT'].split(';') : ['']

      env['PATH'].split(File::PATH_SEPARATOR).each do |path|
        exts.each do |ext|
          exe = File.join(path, "#{cmd}#{ext}")
          return exe if File.executable?(exe) && !File.directory?(exe)
        end
      end

      nil
    end
  end
end
