# frozen_string_literal: true

module Groups
  module ImportExport
    class ExportService
      def initialize(group:, user:, params: {})
        @group = group
        @current_user = user
        @params = params
        @shared = @params[:shared] || Gitlab::ImportExport::Shared.new(@group)
        @logger = Gitlab::Export::Logger.build
      end

      def async_execute
        GroupExportWorker.perform_async(current_user.id, group.id, params)
      end

      def execute
        validate_user_permissions

        remove_existing_export! if group.export_file_exists?

        save!
      ensure
        remove_archive_tmp_dir
      end

      private

      attr_reader :group, :current_user, :params
      attr_accessor :shared

      def validate_user_permissions
        unless current_user.can?(:admin_group, group)
          shared.error(::Gitlab::ImportExport::Error.permission_error(current_user, group))

          notify_error!
        end
      end

      def remove_existing_export!
        import_export_upload = group.import_export_upload

        import_export_upload.remove_export_file!
        import_export_upload.save
      end

      def save!
        # We cannot include the file_saver with the other savers because
        # it removes the tmp dir. This means that if we want to add new savers
        # in EE the data won't be available.
        if savers.all?(&:save) && file_saver.save
          notify_success
        else
          notify_error!
        end
      end

      def savers
        [version_saver, tree_exporter]
      end

      def tree_exporter
        tree_exporter_class.new(
          group: group,
          current_user: current_user,
          shared: shared,
          params: params
        )
      end

      def tree_exporter_class
        if ndjson?
          Gitlab::ImportExport::Group::TreeSaver
        else
          Gitlab::ImportExport::Group::LegacyTreeSaver
        end
      end

      def ndjson?
        ::Feature.enabled?(:group_export_ndjson, group&.parent, default_enabled: :yaml)
      end

      def version_saver
        Gitlab::ImportExport::VersionSaver.new(shared: shared)
      end

      def file_saver
        Gitlab::ImportExport::Saver.new(exportable: group, shared: shared)
      end

      def remove_archive_tmp_dir
        FileUtils.rm_rf(shared.archive_path) if shared&.archive_path
      end

      def notify_error!
        notify_error

        raise Gitlab::ImportExport::Error, shared.errors.to_sentence
      end

      def notify_success
        @logger.info(
          message: 'Group Export succeeded',
          group_id: group.id,
          group_name: group.name
        )

        notification_service.group_was_exported(group, current_user)
      end

      def notify_error
        @logger.error(
          message: 'Group Export failed',
          group_id: group.id,
          group_name: group.name,
          errors: shared.errors.join(', ')
        )

        notification_service.group_was_not_exported(group, current_user, shared.errors)
      end

      def notification_service
        @notification_service ||= NotificationService.new
      end
    end
  end
end

Groups::ImportExport::ExportService.prepend_mod_with('Groups::ImportExport::ExportService')
