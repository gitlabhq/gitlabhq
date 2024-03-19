# frozen_string_literal: true

module Backup
  module Tasks
    class Pages < Task
      # pages used to deploy tmp files to this path
      # if some of these files are still there, we don't need them in the backup
      LEGACY_PAGES_TMP_PATH = '@pages.tmp'

      def self.id = 'pages'

      def human_name = _('pages')

      def destination_path = 'pages.tar.gz'

      private

      def target
        @target ||= ::Backup::Targets::Files.new(
          progress, storage_path, options: options, excludes: [LEGACY_PAGES_TMP_PATH])
      end

      def storage_path
        Gitlab.config.pages.path
      end
    end
  end
end
