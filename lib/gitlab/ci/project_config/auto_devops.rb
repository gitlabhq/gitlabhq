# frozen_string_literal: true

module Gitlab
  module Ci
    class ProjectConfig
      class AutoDevops < Source
        def content
          strong_memoize(:content) do
            next unless project&.auto_devops_enabled?

            template = Gitlab::Template::GitlabCiYmlTemplate.find(template_name)
            YAML.dump('include' => [{ 'template' => template.full_name }])
          end
        end

        def internal_include_prepended?
          true
        end

        def source
          :auto_devops_source
        end

        private

        def template_name
          'Auto-DevOps'
        end
      end
    end
  end
end
