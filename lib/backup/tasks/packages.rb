# frozen_string_literal: true

module Backup
  module Tasks
    class Packages < Task
      def self.id = 'packages'

      def human_name = _('packages')

      def destination_path = 'packages.tar.gz'

      private

      def target
        @target ||= ::Backup::Targets::Files.new(progress, storage_path, options: options, excludes: ['tmp'])
      end

      def storage_path
        Settings.packages.storage_path
      end
    end
  end
end
