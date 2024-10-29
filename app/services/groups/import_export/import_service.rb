# frozen_string_literal: true

module Groups
  module ImportExport
    class ImportService
      attr_reader :current_user, :group, :shared

      def initialize(group:, user:)
        @group = group
        @current_user = user
        @user_role = user_role
        @shared = Gitlab::ImportExport::Shared.new(@group)
        @logger = ::Import::Framework::Logger.build
      end

      def async_execute
        group_import_state = GroupImportState.safe_find_or_create_by!(group: group, user: current_user)
        jid = GroupImportWorker.with_status.perform_async(current_user.id, group.id)

        if jid.present?
          group_import_state.update!(jid: jid)
        else
          group_import_state.fail_op('Failed to schedule import job')

          false
        end
      end

      def execute
        Gitlab::Tracking.event(self.class.name, 'create', label: 'import_group_from_file')

        if valid_user_permissions? && import_file && valid_import_file? && restorers.all?(&:restore)
          notify_success

          Gitlab::Tracking.event(
            self.class.name,
            'create',
            label: 'import_access_level',
            user: current_user,
            extra: { user_role: user_role, import_type: 'import_group_from_file' }
          )

          group
        else
          notify_error!
        end

      ensure
        remove_base_tmp_dir
        remove_import_file
      end

      private

      def user_role
        # rubocop:disable Style/MultilineTernaryOperator
        access_level = group.parent ?
          current_user&.group_members&.find_by(source_id: group.parent&.id)&.access_level :
          Gitlab::Access::OWNER
        Gitlab::Access.human_access(access_level)
        # rubocop:enable Style/MultilineTernaryOperator
      end

      def import_file
        @import_file ||= Gitlab::ImportExport::FileImporter.import(
          importable: group,
          archive_file: nil,
          shared: shared,
          user: current_user
        )
      end

      def restorers
        [tree_restorer]
      end

      def tree_restorer
        @tree_restorer ||=
          Gitlab::ImportExport::Group::TreeRestorer.new(
            user: current_user,
            shared: shared,
            group: group
          )
      end

      def remove_import_file
        upload = group.import_export_upload_by_user(current_user)

        return unless upload&.import_file&.file

        upload.remove_import_file!
        upload.save!
      end

      def valid_user_permissions?
        if current_user.can?(:admin_group, group)
          true
        else
          shared.error(::Gitlab::ImportExport::Error.permission_error(current_user, group))

          false
        end
      end

      def valid_import_file?
        return true if File.exist?(File.join(shared.export_path, 'tree/groups/_all.ndjson'))

        shared.error(::Gitlab::ImportExport::Error.incompatible_import_file_error)

        false
      end

      def notify_success
        @logger.info(
          group_id: group.id,
          group_name: group.name,
          message: 'Group Import/Export: Import succeeded'
        )
      end

      def notify_error
        @logger.error(
          group_id: group.id,
          group_name: group.name,
          message: "Group Import/Export: Errors occurred, see '#{Gitlab::ErrorTracking::Logger.file_name}' for details"
        )
      end

      def notify_error!
        notify_error

        raise Gitlab::ImportExport::Error, shared.errors.to_sentence
      end

      def remove_base_tmp_dir
        FileUtils.rm_rf(shared.base_path)
      end
    end
  end
end

Groups::ImportExport::ImportService.prepend_mod_with('Groups::ImportExport::ImportService')
