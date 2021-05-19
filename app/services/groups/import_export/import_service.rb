# frozen_string_literal: true

module Groups
  module ImportExport
    class ImportService
      attr_reader :current_user, :group, :shared

      def initialize(group:, user:)
        @group = group
        @current_user = user
        @shared = Gitlab::ImportExport::Shared.new(@group)
        @logger = Gitlab::Import::Logger.build
      end

      def async_execute
        group_import_state = GroupImportState.safe_find_or_create_by!(group: group, user: current_user)
        jid = GroupImportWorker.perform_async(current_user.id, group.id)

        if jid.present?
          group_import_state.update!(jid: jid)
        else
          group_import_state.fail_op('Failed to schedule import job')

          false
        end
      end

      def execute
        if valid_user_permissions? && import_file && restorers.all?(&:restore)
          notify_success

          group
        else
          notify_error!
        end

      ensure
        remove_base_tmp_dir
        remove_import_file
      end

      private

      def import_file
        @import_file ||= Gitlab::ImportExport::FileImporter.import(
          importable: group,
          archive_file: nil,
          shared: shared
        )
      end

      def restorers
        [tree_restorer]
      end

      def tree_restorer
        @tree_restorer ||=
          if ndjson?
            Gitlab::ImportExport::Group::TreeRestorer.new(
              user: current_user,
              shared: shared,
              group: group
            )
          else
            Gitlab::ImportExport::Group::LegacyTreeRestorer.new(
              user: current_user,
              shared: shared,
              group: group,
              group_hash: nil
            )
          end
      end

      def ndjson?
        ::Feature.enabled?(:group_import_ndjson, group&.parent, default_enabled: true) &&
          File.exist?(File.join(shared.export_path, 'tree/groups/_all.ndjson'))
      end

      def remove_import_file
        upload = group.import_export_upload

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

      def notify_success
        @logger.info(
          group_id:   group.id,
          group_name: group.name,
          message:    'Group Import/Export: Import succeeded'
        )
      end

      def notify_error
        @logger.error(
          group_id:   group.id,
          group_name: group.name,
          message:    "Group Import/Export: Errors occurred, see '#{Gitlab::ErrorTracking::Logger.file_name}' for details"
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
