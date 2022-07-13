# frozen_string_literal: true

module Packages
  module Cleanup
    class Policy < ApplicationRecord
      include Schedulable

      KEEP_N_DUPLICATED_PACKAGE_FILES_VALUES = %w[all 1 10 20 30 40 50].freeze

      self.primary_key = :project_id

      belongs_to :project

      validates :project, presence: true
      validates :keep_n_duplicated_package_files,
                inclusion: {
                  in: KEEP_N_DUPLICATED_PACKAGE_FILES_VALUES,
                  message: 'is invalid'
                }

      # used by Schedulable
      def self.active
        where.not(keep_n_duplicated_package_files: 'all')
      end

      def set_next_run_at
        # fixed cadence of 12 hours
        self.next_run_at = Time.zone.now + 12.hours
      end

      def keep_n_duplicated_package_files_disabled?
        keep_n_duplicated_package_files == 'all'
      end
    end
  end
end
