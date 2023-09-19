# frozen_string_literal: true

module Gitlab
  class Logger < ::Logger
    def self.file_name
      file_name_noext + '.log'
    end

    def self.debug(message)
      build.debug(message)
    end

    def self.error(message)
      build.error(message)
    end

    def self.warn(message)
      build.warn(message)
    end

    def self.info(message)
      build.info(message)
    end

    def self.read_latest
      path = self.full_log_path

      return [] unless File.readable?(path)

      tail_output, _ = Gitlab::Popen.popen(%W[tail -n 2000 #{path}])
      tail_output.split("\n")
    end

    def self.build
      Gitlab::SafeRequestStore[self.cache_key] ||=
        new(self.full_log_path, level: log_level)
    end

    def self.log_level(fallback: ::Logger::DEBUG)
      ENV.fetch('GITLAB_LOG_LEVEL', fallback)
    end

    def self.full_log_path
      Rails.root.join("log", file_name)
    end

    def self.cache_key
      'logger:' + self.full_log_path.to_s
    end
  end
end
