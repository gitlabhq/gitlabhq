# frozen_string_literal: true

module Backup
  module Restore
    module PoolRepositories
      Result = Struct.new(:disk_path, :status, :error_message, keyword_init: true)

      def self.reinitialize_pools!
        PoolRepository.includes(:source_project).find_each do |pool|
          unless pool.source_project && pool.can_reinitialize?
            yield Result.new(disk_path: pool.disk_path, status: :skipped, error_message: nil)

            next
          end

          pool.reinitialize
          pool.schedule

          yield Result.new(disk_path: pool.disk_path, status: :scheduled, error_message: nil)
        rescue StandardError => e
          yield Result.new(disk_path: pool.disk_path, status: :failed, error_message: e.message)
        end
      end
    end
  end
end
