# frozen_string_literal: true

module Projects
  module HashedStorage
    AttachmentMigrationError = Class.new(StandardError)

    AttachmentCannotMoveError = Class.new(StandardError)

    class BaseAttachmentService < BaseService
      # Returns the disk_path value before the execution
      attr_reader :old_disk_path

      # Returns the disk_path value after the execution
      attr_reader :new_disk_path

      # Returns the logger currently in use
      attr_reader :logger

      def initialize(project:, old_disk_path:, logger: nil)
        @project = project
        @old_disk_path = old_disk_path
        @logger = logger || Gitlab::AppLogger
      end

      # Return whether this operation was skipped or not
      #
      # @return [Boolean] true if skipped of false otherwise
      def skipped?
        @skipped
      end

      # Check if target path has discardable content
      #
      # @param [String] new_path
      # @return [Boolean] whether we can discard the target path or not
      def target_path_discardable?(new_path)
        false
      end

      protected

      def move_folder!(old_path, new_path)
        unless File.directory?(old_path)
          logger.info("Skipped attachments move from '#{old_path}' to '#{new_path}', source path doesn't exist or is not a directory (PROJECT_ID=#{project.id})")
          @skipped = true

          return true
        end

        if File.exist?(new_path)
          if target_path_discardable?(new_path)
            discard_path!(new_path)
          else
            logger.error("Cannot move attachments from '#{old_path}' to '#{new_path}', target path already exist (PROJECT_ID=#{project.id})")

            raise AttachmentCannotMoveError, "Target path '#{new_path}' already exists"
          end
        end

        # Create base path folder on the new storage layout
        FileUtils.mkdir_p(File.dirname(new_path))

        FileUtils.mv(old_path, new_path)
        logger.info("Project attachments moved from '#{old_path}' to '#{new_path}' (PROJECT_ID=#{project.id})")

        true
      end

      # Rename a path adding a suffix in order to prevent data-loss.
      #
      # @param [String] new_path
      def discard_path!(new_path)
        discarded_path = "#{new_path}-#{Time.current.utc.to_i}"

        logger.info("Moving existing empty attachments folder from '#{new_path}' to '#{discarded_path}', (PROJECT_ID=#{project.id})")
        FileUtils.mv(new_path, discarded_path)
      end
    end
  end
end
