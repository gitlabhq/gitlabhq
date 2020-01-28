# frozen_string_literal: true

module Groups
  module ImportExport
    class ImportService
      attr_reader :current_user, :group, :params

      def initialize(group:, user:)
        @group = group
        @current_user = user
        @shared = Gitlab::ImportExport::Shared.new(@group)
      end

      def execute
        validate_user_permissions

        if import_file && restorer.restore
          @group
        else
          raise StandardError.new(@shared.errors.to_sentence)
        end
      rescue => e
        raise StandardError.new(e.message)
      ensure
        remove_import_file
      end

      private

      def import_file
        @import_file ||= Gitlab::ImportExport::FileImporter.import(importable: @group,
                                                                   archive_file: nil,
                                                                   shared: @shared)
      end

      def restorer
        @restorer ||= Gitlab::ImportExport::GroupTreeRestorer.new(user: @current_user,
                                                                  shared: @shared,
                                                                  group: @group,
                                                                  group_hash: nil)
      end

      def remove_import_file
        upload = @group.import_export_upload

        return unless upload&.import_file&.file

        upload.remove_import_file!
        upload.save!
      end

      def validate_user_permissions
        unless current_user.can?(:admin_group, group)
          raise ::Gitlab::ImportExport::Error.new(
            "User with ID: %s does not have permission to Group %s with ID: %s." %
              [current_user.id, group.name, group.id])
        end
      end
    end
  end
end
