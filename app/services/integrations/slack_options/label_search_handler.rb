# frozen_string_literal: true

module Integrations
  module SlackOptions
    class LabelSearchHandler # rubocop:disable Search/NamespacedClass
      include Gitlab::Utils::StrongMemoize

      def initialize(current_user, search_value, view_id)
        @current_user = current_user.user
        @search_value = search_value
        @view_id = view_id
      end

      def execute
        return ServiceResponse.success(payload: []) unless current_user.can?(:read_label, project)

        labels = LabelsFinder.new(
          current_user,
          {
            project: project,
            search: search_value
          }
        ).execute

        ServiceResponse.success(payload: build_label_list(labels))
      end

      private

      def project
        project_id = Integrations::SlackInteractions::IncidentManagement::IncidentModalOpenedService
              .cache_read(view_id)

        return unless project_id

        Project.find(project_id)
      end
      strong_memoize_attr :project

      def build_label_list(labels)
        return [] unless labels

        label_list = labels.map do |label|
          {
            text: {
              type: "plain_text",
              text: label.name
            },
            value: label.id.to_s
          }
        end

        {
          options: label_list
        }
      end

      attr_accessor :current_user, :search_value, :view_id
    end
  end
end
