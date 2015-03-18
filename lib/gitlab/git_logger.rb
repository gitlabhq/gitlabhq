module Gitlab
  class GitLogger < Gitlab::Logger
    def self.file_name_noext
      'githost'
    end

    def format_message(severity, timestamp, progname, msg)
      "#{timestamp.to_s(:long)} -> #{severity} -> #{msg}\n"
    end
  end
end
