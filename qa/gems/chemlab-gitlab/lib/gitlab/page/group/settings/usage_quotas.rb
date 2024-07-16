# frozen_string_literal: true

module Gitlab
  module Page
    module Group
      module Settings
        class UsageQuotas < Chemlab::Page
          # Storage section
          link :storage_tab
          div :namespace_usage_total
          span :group_usage_message
          span :dependency_proxy_size
          span :project_repository_size
          span :project_wiki_size
          span :project_snippets_size
          span :project_containers_registry_size

          # Pending members
          div :pending_members
          button :approve_member
          button :confirm_member_approval, text: /^OK$/
        end
      end
    end
  end
end
