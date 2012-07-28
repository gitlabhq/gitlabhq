module Gitlab
  class Logger < ::Logger
    def self.error(message)
      build.error(message)
    end

    def self.info(message)
      build.info(message)
    end

    def self.read_latest
      path = Rails.root.join("log/githost.log")
      self.build unless File.exist?(path)
      logs = File.read(path).split("\n")
    end

    def self.build
      new(File.join(Rails.root, "log/githost.log"))
    end

    def format_message(severity, timestamp, progname, msg)
      "#{timestamp.to_s(:long)} -> #{severity} -> #{msg}\n" 
    end 
  end
end
