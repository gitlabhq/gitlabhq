# frozen_string_literal: true

module Backup
  module Tasks
    class Uploads < Task
      def self.id = 'uploads'

      def human_name
        _('uploads')
      end

      def destination_path
        'uploads.tar.gz'
      end

      private

      def target
        @target ||= ::Backup::Targets::Files.new(progress, storage_path, options: options, excludes: ['tmp'])
      end

      def storage_path
        File.join(Gitlab.config.uploads.storage_path, 'uploads')
      end
    end
  end
end
