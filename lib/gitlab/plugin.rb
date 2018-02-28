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
      [exit_status.zero?, result.stderr]
    rescue => e
      [false, e.message]
    end
  end
end
