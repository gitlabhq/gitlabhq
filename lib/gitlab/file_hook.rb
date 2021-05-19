# frozen_string_literal: true

module Gitlab
  module FileHook
    def self.any?
      dir_glob.any? { |entry| File.file?(entry) }
    end

    def self.files
      dir_glob.select { |entry| File.file?(entry) }
    end

    def self.dir_glob
      Dir.glob(Rails.root.join('file_hooks/*'))
    end
    private_class_method :dir_glob

    def self.execute_all_async(data)
      args = files.map { |file| [file, data] }

      FileHookWorker.bulk_perform_async(args) # rubocop:disable Scalability/BulkPerformWithContext
    end

    def self.execute(file, data)
      result = Gitlab::Popen.popen_with_detail([file]) do |stdin|
        stdin.write(data.to_json)
      end

      exit_status = result.status&.exitstatus
      [exit_status == 0, result.stderr]
    rescue StandardError => e
      [false, e.message]
    end
  end
end
