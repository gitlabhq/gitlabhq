# frozen_string_literal: true

module Import
  module SourceUsers
    class KeepAllAsPlaceholderService < BaseService
      BATCH_SIZE = 1000

      def initialize(namespace, current_user:)
        @namespace = namespace
        @current_user = current_user
      end

      def execute
        return error_invalid_permissions unless current_user.can?(:admin_namespace, namespace)

        updated_source_user_count = 0

        namespace.import_source_users.by_statuses(
          Import::SourceUser::STATUSES.slice(*Import::SourceUser::REASSIGNABLE_STATUSES).values
        ).each_batch(of: BATCH_SIZE) do |source_user_batch|
          updated_source_user_count += source_user_batch.update_all(
            status: Import::SourceUser::STATUSES[:keep_as_placeholder],
            reassign_to_user_id: nil,
            reassigned_by_user_id: current_user.id
          )
        end

        ServiceResponse.success(payload: updated_source_user_count)
      end

      private

      attr_reader :namespace
    end
  end
end
