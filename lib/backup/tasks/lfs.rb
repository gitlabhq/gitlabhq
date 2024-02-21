# frozen_string_literal: true

module Backup
  module Tasks
    class Lfs < Task
      def self.id = 'lfs'

      def human_name = _('lfs objects')

      def destination_path = 'lfs.tar.gz'

      def target
        ::Backup::Targets::Files.new(progress, storage_path, options: options)
      end

      private

      def storage_path
        Settings.lfs.storage_path
      end
    end
  end
end
