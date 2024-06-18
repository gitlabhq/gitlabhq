# frozen_string_literal: true

module Backup
  module Tasks
    class ExternalDiffs < Task
      def self.id = 'external_diffs'

      def human_name = _('external diffs')

      def destination_path = 'external_diffs.tar.gz'

      private

      def target
        @target ||= ::Backup::Targets::Files.new(progress, storage_path, options: options, excludes: ['tmp'])
      end

      def storage_path
        Settings.external_diffs.storage_path
      end
    end
  end
end
