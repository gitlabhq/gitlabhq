# frozen_string_literal: true

module Import
  module PlaceholderMemberships
    class CreateService
      include Services::ReturnServiceResponses

      def initialize(
        source_user:, access_level:, expires_at: nil, group: nil, project: nil,
        ignore_duplicate_errors: false)
        @ignore_duplicate_errors = ignore_duplicate_errors
        @reference = Import::Placeholders::Membership.new(
          source_user: source_user,
          namespace_id: source_user.namespace_id,
          group: group,
          project: project,
          expires_at: expires_at,
          access_level: access_level
        )
      end

      def execute
        return success(reference: reference) if reference.save

        if ignore_duplicate_errors?(reference)
          log_duplicate_membership
          return success(reference: reference)
        end

        error(reference.errors.full_messages, :bad_request)
      end

      private

      attr_reader :reference, :ignore_duplicate_errors

      def ignore_duplicate_errors?(reference)
        ignore_duplicate_errors && (reference.errors.of_kind?(:project_id, :taken) ||
          reference.errors.of_kind?(:group_id, :taken))
      end

      def log_duplicate_membership
        logger.info(
          message: 'Project or group has already been taken. Skipping placeholder membership creation',
          reference: reference
        )
      end

      def logger
        @logger ||= ::Import::Framework::Logger.build
      end
    end
  end
end
