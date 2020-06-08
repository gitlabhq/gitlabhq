# frozen_string_literal: true

module PerformanceMonitoring
  class PrometheusDashboard
    include ActiveModel::Model

    attr_accessor :dashboard, :panel_groups, :path, :environment, :priority, :templating, :links

    validates :dashboard, presence: true
    validates :panel_groups, presence: true

    class << self
      def from_json(json_content)
        build_from_hash(json_content).tap(&:validate!)
      end

      def find_for(project:, user:, path:, options: {})
        template = { path: path, environment: options[:environment] }
        rsp = Gitlab::Metrics::Dashboard::Finder.find(project, user, options.merge(dashboard_path: path))

        case rsp[:http_status] || rsp[:status]
        when :success
          new(template.merge(rsp[:dashboard] || {})) # when there is empty dashboard file returned rsp is still a success
        when :unprocessable_entity
          new(template) # validation error
        else
          nil # any other error
        end
      end

      private

      def build_from_hash(attributes)
        return new unless attributes.is_a?(Hash)

        new(
          dashboard: attributes['dashboard'],
          panel_groups: attributes['panel_groups']&.map { |group| PrometheusPanelGroup.from_json(group) }
        )
      end
    end

    def to_yaml
      self.as_json(only: yaml_valid_attributes).to_yaml
    end

    # This method is planned to be refactored as a part of https://gitlab.com/gitlab-org/gitlab/-/issues/219398
    # implementation. For new existing logic was reused to faster deliver MVC
    def schema_validation_warnings
      self.class.from_json(self.as_json)
      nil
    rescue ActiveModel::ValidationError => exception
      exception.model.errors.map { |attr, error| "#{attr}: #{error}" }
    end

    private

    def yaml_valid_attributes
      %w(panel_groups panels metrics group priority type title y_label weight id unit label query query_range dashboard)
    end
  end
end
