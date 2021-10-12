# frozen_string_literal: true

module Gitlab
  module Page
    module Group
      module Settings
        class UsageQuotas < Chemlab::Page
          link :pipeline_tab, id: 'pipelines-quota'
          link :storage_tab, id: 'storage-quota'
          link :buy_ci_minutes, text: 'Buy additional minutes'
          link :buy_storage, text: /Purchase more storage/
          strong :additional_minutes, text: 'Additional minutes'
          div(:additional_minutes_usage) { additional_minutes_element.following_sibling.span }
          div :purchase_successful_alert, text: /You have successfully purchased CI minutes/

          def plan_minutes_limits
            plan_minutes_usage[%r{([^/ ]+)$}]
          end

          def additional_limits
            additional_minutes_usage[%r{([^/ ]+)$}]
          end
        end
      end
    end
  end
end
