# frozen_string_literal: true

module PerformanceMonitoring
  class PrometheusDashboard
    include ActiveModel::Model

    attr_accessor :dashboard, :panel_groups, :path, :environment, :priority, :templating, :links

    validates :dashboard, presence: true
    validates :panel_groups, array_members: { member_class: PerformanceMonitoring::PrometheusPanelGroup }

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
          panel_groups: initialize_children_collection(attributes['panel_groups'])
        )
      end

      def initialize_children_collection(children)
        return unless children.is_a?(Array)

        children.map { |group| PerformanceMonitoring::PrometheusPanelGroup.from_json(group) }
      end
    end

    def to_yaml
      self.as_json(only: yaml_valid_attributes).to_yaml
    end

    # This method is planned to be refactored as a part of https://gitlab.com/gitlab-org/gitlab/-/issues/219398
    # implementation. For new existing logic was reused to faster deliver MVC
    def schema_validation_warnings
      return run_custom_validation.map(&:message) if Feature.enabled?(:metrics_dashboard_exhaustive_validations, environment&.project)

      self.class.from_json(reload_schema)
      []
    rescue Gitlab::Metrics::Dashboard::Errors::LayoutError => error
      [error.message]
    rescue ActiveModel::ValidationError => exception
      exception.model.errors.map { |attr, error| "#{attr}: #{error}" }
    end

    private

    def run_custom_validation
      Gitlab::Metrics::Dashboard::Validator
        .errors(reload_schema, dashboard_path: path, project: environment&.project)
    end

    # dashboard finder methods are somehow limited, #find includes checking if
    # user is authorised to view selected dashboard, but modifies schema, which in some cases may
    # cause false positives returned from validation, and #find_raw does not authorise users
    def reload_schema
      project = environment&.project
      project.nil? ? self.as_json : Gitlab::Metrics::Dashboard::Finder.find_raw(project, dashboard_path: path)
    end

    def yaml_valid_attributes
      %w(panel_groups panels metrics group priority type title y_label weight id unit label query query_range dashboard)
    end
  end
end
