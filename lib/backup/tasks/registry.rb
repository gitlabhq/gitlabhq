# frozen_string_literal: true

module Backup
  module Tasks
    class Registry < Task
      def self.id = 'registry'

      def enabled = Gitlab.config.registry.enabled

      def human_name = _('container registry images')

      def destination_path = 'registry.tar.gz'

      def target
        ::Backup::Targets::Files.new(progress, app_files_dir, options: options)
      end

      private

      def app_files_dir
        Settings.registry.path
      end
    end
  end
end
