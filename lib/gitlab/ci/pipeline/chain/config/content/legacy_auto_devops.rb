# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        module Config
          class Content
            class LegacyAutoDevops < Source
              def content
                strong_memoize(:content) do
                  next unless project&.auto_devops_enabled?

                  template = Gitlab::Template::GitlabCiYmlTemplate.find(template_name)
                  template.content
                end
              end

              def source
                :auto_devops_source
              end

              private

              def template_name
                if beta_enabled?
                  'Beta/Auto-DevOps'
                else
                  'Auto-DevOps'
                end
              end

              def beta_enabled?
                Feature.enabled?(:auto_devops_beta, project, default_enabled: true) &&
                  # workflow:rules are required by `Beta/Auto-DevOps.gitlab-ci.yml`
                  Feature.enabled?(:workflow_rules, project, default_enabled: true)
              end
            end
          end
        end
      end
    end
  end
end
