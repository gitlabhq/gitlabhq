module Gitlab
  module Plugin
    def self.files
      Dir.glob(Rails.root.join('plugins/*')).select do |entry|
        File.file?(entry)
      end
    end

    def self.execute_all_async(data)
      files.each do |file|
        PluginWorker.perform_async(file, data)
      end
    end

    def self.execute(file, data)
      _output, exit_status = Gitlab::Popen.popen([file]) do |stdin|
        stdin.write(data.to_json)
      end

      exit_status.zero?
    end
  end
end
