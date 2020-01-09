# frozen_string_literal: true

module Gitlab
  module Plugin
    def self.any?
      plugin_glob.any? { |entry| File.file?(entry) }
    end

    def self.files
      plugin_glob.select { |entry| File.file?(entry) }
    end

    def self.plugin_glob
      Dir.glob(Rails.root.join('plugins/*'))
    end

    def self.execute_all_async(data)
      args = files.map { |file| [file, data] }

      PluginWorker.bulk_perform_async(args)
    end

    def self.execute(file, data)
      result = Gitlab::Popen.popen_with_detail([file]) do |stdin|
        stdin.write(data.to_json)
      end

      exit_status = result.status&.exitstatus
      [exit_status.zero?, result.stderr]
    rescue => e
      [false, e.message]
    end
  end
end
