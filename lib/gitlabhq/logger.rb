module Gitlabhq
  class Logger
    def self.error(message)
      @@logger ||= ::Logger.new(File.join(Rails.root, "log/githost.log"))
      @@logger.error(message)
    end
  end
end
