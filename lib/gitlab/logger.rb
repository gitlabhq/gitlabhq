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
      tail_output, _ = Gitlab::Popen.popen(%W(tail -n 2000 #{path}))
      tail_output.split("\n")
    end

    def self.read_latest_for filename
      path = Rails.root.join("log", filename)
      tail_output, _ = Gitlab::Popen.popen(%W(tail -n 2000 #{path}))
      tail_output.split("\n")
    end

    def self.build
      new(Rails.root.join("log", file_name))
    end
  end
end
