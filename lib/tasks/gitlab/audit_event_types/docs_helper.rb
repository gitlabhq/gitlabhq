# frozen_string_literal: true

module Tasks
  module Gitlab
    module AuditEventTypes
      module DocsHelper
        def boolean_to_docs(boolean)
          boolean ? "{{< yes >}}" : "{{< no >}}"
        end

        def humanize_feature_category(feature_category)
          case feature_category
          when 'duo_workflow' then 'GitLab Duo Agent Platform'
          when 'mlops'        then 'MLOps'
          when 'not_owned'    then 'Not categorized'
          when 'service_desk' then 'Service Desk'
          else
            feature_category.humanize.gsub(/\bAi\b/i, 'AI')
          end
        end
      end
    end
  end
end
