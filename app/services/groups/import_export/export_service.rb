# frozen_string_literal: true

module Groups
  module ImportExport
    class ExportService
      def initialize(group:, user:, exported_by_admin:, params: {})
        @group = group
        @current_user = user
        @exported_by_admin = exported_by_admin
        @params = params
        @shared = @params[:shared] || Gitlab::ImportExport::Shared.new(@group)
        @logger = Gitlab::Export::Logger.build
      end

      def async_execute
        GroupExportWorker.perform_async(
          current_user.id,
          group.id,
          params.merge(exported_by_admin: @exported_by_admin)
        )
      end

      def execute
        validate_user_permissions

        remove_existing_export! if group.export_file_exists?(current_user)

        save!
      ensure
        remove_archive_tmp_dir
      end

      private

      attr_reader :group, :current_user, :exported_by_admin, :params
      attr_accessor :shared

      def validate_user_permissions
        unless current_user.can?(:admin_group, group)
          shared.error(::Gitlab::ImportExport::Error.permission_error(current_user, group))

          notify_error!
        end
      end

      def remove_existing_export!
        import_export_upload = group.import_export_upload_by_user(current_user)

        import_export_upload.remove_export_file!
        import_export_upload.save
      end

      def save!
        # We cannot include the file_saver with the other savers because
        # it removes the tmp dir. This means that if we want to add new savers
        # in EE the data won't be available.
        if save_exporters && file_saver.save
          audit_export
          notify_success
        else
          notify_error!
        end
      end

      def save_exporters
        log_info('Group export started')

        savers.all? do |exporter|
          log_info("#{exporter.class.name} saver started")

          exporter.save
        end
      end

      def savers
        [version_saver, tree_exporter]
      end

      def tree_exporter
        Gitlab::ImportExport::Group::TreeSaver.new(
          group: group,
          current_user: current_user,
          shared: shared,
          params: params
        )
      end

      def version_saver
        Gitlab::ImportExport::VersionSaver.new(shared: shared)
      end

      def file_saver
        Gitlab::ImportExport::Saver.new(exportable: group, shared: shared, user: current_user)
      end

      def remove_archive_tmp_dir
        FileUtils.rm_rf(shared.archive_path) if shared&.archive_path
      end

      def notify_error!
        notify_error

        raise Gitlab::ImportExport::Error, shared.errors.to_sentence
      end

      def log_info(message)
        @logger.info(
          message: message,
          group_id: group.id,
          group_name: group.name
        )
      end

      def audit_export
        return if exported_by_admin && Gitlab::CurrentSettings.silent_admin_exports_enabled?

        audit_context = {
          name: 'group_export_created',
          author: current_user,
          scope: group,
          target: group,
          message: 'Group file export was created'
        }

        Gitlab::Audit::Auditor.audit(audit_context)
      end

      def notify_success
        log_info('Group Export succeeded')

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
