# frozen_string_literal: true

module Gitlab::UsageDataCounters
  class CiTemplateUniqueCounter
    PREFIX = 'ci_templates'

    class << self
      def track_unique_project_event(project:, template:, config_source:, user:)
        expanded_template_name = expand_template_name(template)
        return unless expanded_template_name

        event_name = ci_template_event_name(expanded_template_name, config_source)
        Gitlab::UsageDataCounters::HLLRedisCounter.track_event(event_name, values: project.id)

        namespace = project.namespace
        Gitlab::InternalEvents.track_event('ci_template_included', namespace: namespace, project: project, user: user)
      end

      def ci_templates(relative_base = 'lib/gitlab/ci/templates')
        Dir.glob('**/*.gitlab-ci.yml', base: Rails.root.join(relative_base))
      end

      def ci_template_event_name(template_name, config_source)
        prefix = 'implicit_' if config_source.to_s == 'auto_devops_source'

        "p_#{PREFIX}_#{prefix}#{template_to_event_name(template_name)}"
      end

      def expand_template_name(template_name)
        Gitlab::Template::GitlabCiYmlTemplate.find(template_name.chomp('.gitlab-ci.yml'))&.full_name
      end

      private

      def template_to_event_name(template)
        ActiveSupport::Inflector.parameterize(template.chomp('.gitlab-ci.yml'), separator: '_').underscore
      end
    end
  end
end
