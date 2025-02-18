# frozen_string_literal: true

module Projects
  module LookAheadPreloads
    extend ActiveSupport::Concern

    prepended do
      include ::LooksAhead
    end

    private

    def preloads
      {
        full_path: [:route],
        topics: [:topics],
        import_status: [:import_state],
        service_desk_address: [:project_feature, :service_desk_setting],
        jira_import_status: [:jira_imports],
        container_repositories: [:container_repositories],
        container_repositories_count: [:container_repositories],
        web_url: { namespace: [:route] },
        is_catalog_resource: [:catalog_resource],
        open_merge_requests_count: [:project_feature],
        organization_edit_path: [:organization]
      }
    end
  end
end

Projects::LookAheadPreloads.prepend_mod
