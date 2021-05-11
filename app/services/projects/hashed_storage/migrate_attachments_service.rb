# frozen_string_literal: true

module Projects
  module HashedStorage
    class MigrateAttachmentsService < BaseAttachmentService
      extend ::Gitlab::Utils::Override

      # List of paths that can be excluded while evaluation if a target can be discarded
      DISCARDABLE_PATHS = %w(tmp tmp/cache tmp/work).freeze

      def initialize(project:, old_disk_path:, logger: nil)
        super

        @skipped = false
      end

      def execute
        origin = find_old_attachments_path(project)

        project.storage_version = ::Project::HASHED_STORAGE_FEATURES[:attachments]
        target = FileUploader.absolute_base_dir(project)

        @new_disk_path = project.disk_path

        result = move_folder!(origin, target)

        if result
          project.save!(validate: false)

          yield if block_given?
        end

        result
      end

      override :target_path_discardable?
      # Check if target path has discardable content
      #
      # @param [String] new_path
      # @return [Boolean] whether we can discard the target path or not
      def target_path_discardable?(new_path)
        return false unless File.directory?(new_path)

        found = Dir.glob(File.join(new_path, '**', '**'))

        (found - discardable_paths(new_path)).empty?
      end

      private

      def discardable_paths(new_path)
        DISCARDABLE_PATHS.collect { |path| File.join(new_path, path) }
      end

      def find_old_attachments_path(project)
        origin = FileUploader.absolute_base_dir(project)

        # It's possible that old_disk_path does not match project.disk_path.
        # For example, that happens when we rename a project
        #
        origin.sub(/#{Regexp.escape(project.full_path)}\z/, old_disk_path)
      end
    end
  end
end

Projects::HashedStorage::MigrateAttachmentsService.prepend_mod_with('Projects::HashedStorage::MigrateAttachmentsService')
