# frozen_string_literal: true

module Groups
  module ImportExport
    class ExportService
      def initialize(group:, user:, params: {})
        @group        = group
        @current_user = user
        @params       = params
        @shared       = @params[:shared] || Gitlab::ImportExport::Shared.new(@group)
      end

      def async_execute
        GroupExportWorker.perform_async(@current_user.id, @group.id, @params)
      end

      def execute
        validate_user_permissions

        remove_existing_export! if @group.export_file_exists?

        save!
      ensure
        cleanup
      end

      private

      attr_accessor :shared

      def validate_user_permissions
        unless @current_user.can?(:admin_group, @group)
          @shared.error(::Gitlab::ImportExport::Error.permission_error(@current_user, @group))

          notify_error!
        end
      end

      def remove_existing_export!
        import_export_upload = @group.import_export_upload

        import_export_upload.remove_export_file!
        import_export_upload.save
      end

      def save!
        if savers.all?(&:save)
          notify_success
        else
          notify_error!
        end
      end

      def savers
        [tree_exporter, file_saver]
      end

      def tree_exporter
        tree_exporter_class.new(
          group: @group,
          current_user: @current_user,
          shared: @shared,
          params: @params
        )
      end

      def tree_exporter_class
        if ::Feature.enabled?(:group_import_export_ndjson, @group&.parent)
          Gitlab::ImportExport::Group::TreeSaver
        else
          Gitlab::ImportExport::Group::LegacyTreeSaver
        end
      end

      def file_saver
        Gitlab::ImportExport::Saver.new(exportable: @group, shared: @shared)
      end

      def cleanup
        FileUtils.rm_rf(shared.archive_path) if shared&.archive_path
      end

      def notify_error!
        notify_error

        raise Gitlab::ImportExport::Error.new(shared.errors.to_sentence)
      end

      def notify_success
        @shared.logger.info(
          group_id:   @group.id,
          group_name: @group.name,
          message:    'Group Import/Export: Export succeeded'
        )
      end

      def notify_error
        @shared.logger.error(
          group_id:   @group.id,
          group_name: @group.name,
          error:      @shared.errors.join(', '),
          message:    'Group Import/Export: Export failed'
        )
      end
    end
  end
end
