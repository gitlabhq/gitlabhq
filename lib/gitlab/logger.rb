module Gitlab
  class Logger < ::Logger
    def self.error(message)
      build.error(message)
    end

    def self.info(message)
      build.info(message)
    end

    def self.read_latest
      path = Rails.root.join("log", file_name)
      self.build unless File.exist?(path)
      logs = File.read(path).split("\n")
    end

    def self.build
      new(Rails.root.join("log", file_name))
    end
  end
end
