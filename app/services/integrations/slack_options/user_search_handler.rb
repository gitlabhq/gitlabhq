# frozen_string_literal: true

module Integrations
  module SlackOptions
    class UserSearchHandler # rubocop:disable Search/NamespacedClass
      include Gitlab::Utils::StrongMemoize

      def initialize(current_user, search_value, view_id)
        @current_user = current_user.user
        @search_value = search_value
        @view_id = view_id
      end

      def execute
        return ServiceResponse.success(payload: []) unless current_user.can?(:read_project_member, project)

        members = MembersFinder.new(project, current_user, params: { search: search_value }).execute

        ServiceResponse.success(payload: build_user_list(members))
      end

      private

      def project
        project_id = SlackInteractions::IncidentManagement::IncidentModalOpenedService
              .cache_read(view_id)

        return unless project_id

        Project.find(project_id)
      end
      strong_memoize_attr :project

      def build_user_list(members)
        return [] unless members

        user_list = members.map do |member|
          {
            text: {
              type: "plain_text",
              text: "#{member.user.name} - #{member.user.username}"
            },
            value: member.user.id.to_s
          }
        end

        {
          options: user_list
        }
      end

      attr_reader :current_user, :search_value, :view_id
    end
  end
end
