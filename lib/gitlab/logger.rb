module Gitlab
  class Logger
    def self.error(message)
      @@logger ||= ::Logger.new(File.join(Rails.root, "log/githost.log"))
      message = Time.now.to_s(:long) + " -> " + message
      @@logger.error(message)
    end

    def self.read_latest
      path = Rails.root.join("log/githost.log")
      logs = File.read(path).split("\n")
    end
  end
end
