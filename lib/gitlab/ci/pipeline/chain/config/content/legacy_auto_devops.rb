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

                  template = Gitlab::Template::GitlabCiYmlTemplate.find('Auto-DevOps')
                  template.content
                end
              end

              def source
                :auto_devops_source
              end
            end
          end
        end
      end
    end
  end
end
