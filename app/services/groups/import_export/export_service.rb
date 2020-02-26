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

      def execute
        unless @current_user.can?(:admin_group, @group)
          raise ::Gitlab::ImportExport::Error.new(
            "User with ID: %s does not have permission to Group %s with ID: %s." %
              [@current_user.id, @group.name, @group.id])
        end

        save!
      ensure
        cleanup
      end

      private

      attr_accessor :shared

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
        Gitlab::ImportExport::Group::TreeSaver.new(group: @group, current_user: @current_user, shared: @shared, params: @params)
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
