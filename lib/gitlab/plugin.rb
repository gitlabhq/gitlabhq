module Gitlab
  module Plugin
    def self.files
      Dir.glob(Rails.root.join('plugins/*')).select do |entry|
        File.file?(entry)
      end
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

      unless exit_status.zero?
        Rails.logger.error("Plugin Error => #{file}: #{result.stderr}")
      end

      exit_status.zero?
    rescue => e
      Rails.logger.error("Plugin Error => #{file}: #{e.message}")
      false
    end
  end
end
