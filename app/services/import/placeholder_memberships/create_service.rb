# frozen_string_literal: true

module Import
  module PlaceholderMemberships
    class CreateService
      include Services::ReturnServiceResponses

      def initialize(source_user:, access_level:, expires_at: nil, group: nil, project: nil)
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

        error(reference.errors.full_messages, :bad_request)
      end

      private

      attr_reader :reference
    end
  end
end
