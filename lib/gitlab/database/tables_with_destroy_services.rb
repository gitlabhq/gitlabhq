# frozen_string_literal: true

module Gitlab
  module Database
    # Maps database tables to the dedicated service that deletes their records,
    # derived from app/services/**/{destroy_service,delete_service}.rb. Used by
    # the Migration/ForeignKeysToDestroyServiceTables cop and the spec that
    # checks foreign keys to these tables are handled by the owning service, so
    # it must stay loadable without Rails.
    #
    # Every discovered service namespace must resolve to a table documented in
    # db/docs (by convention or via TABLE_OVERRIDES) or be listed in
    # EXCLUDED_NAMESPACES; anything else surfaces in unaccounted_namespaces,
    # which a spec requires to stay empty so no service is silently skipped.
    # Deletion services that follow neither file naming convention are mapped
    # through EXTRA_TABLES_TO_SERVICES.
    module TablesWithDestroyServices
      # Service namespaces whose owned table does not follow the
      # `app/services/<namespace>` => `<namespace with underscores>` convention.
      TABLE_OVERRIDES = {
        'ai/catalog/agents' => 'ai_catalog_items',
        'ai/catalog/flows' => 'ai_catalog_items',
        'ai/catalog/third_party_flows' => 'ai_catalog_items',
        'ai/self_hosted_models/testing_terms_acceptance' => 'ai_testing_terms_acceptances',
        'analytics/custom_dashboards' => 'custom_dashboards',
        'analytics/devops_adoption/enabled_namespaces' => 'analytics_devops_adoption_segments',
        'app_sec/dast/profiles' => 'dast_profiles',
        'app_sec/dast/scanner_profiles' => 'dast_scanner_profiles',
        'app_sec/dast/site_profile_secret_variables' => 'dast_site_profile_secret_variables',
        'app_sec/dast/site_profiles' => 'dast_site_profiles',
        'audit_events/group/event_type_filters/denylist' => 'audit_events_group_streaming_event_type_filters',
        'audit_events/streaming/instance_headers' => 'instance_audit_events_streaming_headers',
        'authn/applications' => 'oauth_applications',
        'authn/passkey' => 'webauthn_registrations',
        'authz/admin_roles' => 'admin_roles',
        'authz/ldap_admin_role_links' => 'ldap_admin_role_links',
        'award_emojis' => 'award_emoji',
        'boards/lists' => 'lists',
        'branch_rules/external_status_checks' => 'external_status_checks',
        'ci/catalog/resources' => 'catalog_resources',
        'ci/deployments' => 'deployments',
        'ci/pipeline_triggers' => 'ci_triggers',
        'clusters/agents' => 'cluster_agents',
        'clusters/agents/managed_resources' => 'clusters_managed_resources',
        'compliance_management/compliance_framework/compliance_requirements' => 'compliance_requirements',
        'compliance_management/compliance_framework/compliance_requirements_controls' =>
          'compliance_requirements_controls',
        'feature_flag_issues' => 'operations_feature_flags_issues',
        'feature_flags' => 'operations_feature_flags',
        'group_saml/identity' => 'identities',
        'group_saml/saml_group_links' => 'saml_group_links',
        'groups' => 'namespaces',
        'groups/deploy_tokens' => 'deploy_tokens',
        'groups/group_links' => 'group_group_links',
        'groups/ssh_certificates' => 'group_ssh_certificates',
        'incident_management/issuable_resource_links' => 'issuable_resource_links',
        'iterations' => 'sprints',
        'merge_requests/saved_views' => 'saved_views',
        'organizations/organization_users' => 'organization_users',
        'projects/container_repository' => 'container_repositories',
        'projects/deploy_tokens' => 'deploy_tokens',
        'projects/group_links' => 'project_group_links',
        'releases/links' => 'release_links',
        'two_factor' => 'webauthn_registrations',
        'users/abuse/namespace_bans' => 'namespace_bans',
        'webauthn' => 'webauthn_registrations',
        'work_items/legacy_epics/epic_issues' => 'epic_issues',
        'work_items/legacy_epics/related_epic_links' => 'related_epic_links',
        'work_items/lifecycles' => 'work_item_custom_lifecycles',
        'work_items/parent_links' => 'work_item_parent_links',
        'work_items/related_work_item_links' => 'issue_links'
      }.freeze

      # Services that do not own a documented table. Reasons:
      # - Git or external data: branches, files, pages, repositories, tags,
      #   wiki_pages, secrets_management/* (OpenBao).
      # - Records owned by another guarded table or service: branch_rules,
      #   work_items (issues), issuable (issues via Issues::DestroyService,
      #   merge_requests via EXTRA_TABLES_TO_SERVICES),
      #   work_items/legacy_epics/epic_links.
      # - Several tables at once: custom_attributes, service_desk/custom_emails,
      #   ai/amazon_q, security/scan_result_policies/approval_rules.
      # - Generic entry points delegating to other services: issuable_links,
      #   merge_requests/work_item_relations, incident_management/link_alerts,
      #   integrations/exclusions, security/.../policy_store.
      # - CI tables already banned from new FKs by
      #   Migration/PreventForeignKeyCreation: ci/job_artifacts.
      EXCLUDED_NAMESPACES = %w[
        ai/amazon_q
        branch_rules
        branch_rules/squash_options
        branches
        ci/job_artifacts
        custom_attributes
        files
        incident_management/link_alerts
        integrations/exclusions
        issuable
        issuable_links
        merge_requests/work_item_relations
        pages
        repositories
        secrets_management/group_secrets
        secrets_management/group_secrets_permissions
        secrets_management/project_secrets
        secrets_management/project_secrets_permissions
        security/scan_result_policies/approval_rules
        security/security_orchestration_policies/policy_store
        service_desk/custom_emails
        tags
        wiki_pages
        work_items
        work_items/legacy_epics/epic_links
      ].freeze

      # Tables guarded by a deletion service that follows neither the
      # destroy_service.rb nor the delete_service.rb naming convention, so the
      # glob cannot find it.
      EXTRA_TABLES_TO_SERVICES = {
        'approval_project_rules' => 'ApprovalRules::ProjectRuleDestroyService',
        'ci_secure_files' => 'Ci::DestroySecureFileService',
        'merge_requests' => 'Issuable::DestroyService',
        'ml_models' => 'Ml::DestroyModelService',
        'organizations' => 'Organizations::HardDeleteService',
        'security_scan_profiles' => 'Security::ScanProfiles::DeleteScanProfileService',
        'vulnerability_exports' => 'Vulnerabilities::Exports::BatchDestroyService'
      }.freeze

      class << self
        # @return [Hash{String => Array<String>}] table name => deletion service class names
        def tables_to_services
          scan unless @tables_to_services

          @tables_to_services
        end

        # @return [Array<String>] namespaces that neither map to a documented
        #   table nor appear in EXCLUDED_NAMESPACES; must stay empty
        def unaccounted_namespaces
          scan unless @unaccounted_namespaces

          @unaccounted_namespaces
        end

        private

        def scan
          tables = EXTRA_TABLES_TO_SERVICES.transform_values { |service| [service] }
          unaccounted = []

          Dir.glob('{app,ee/app}/services/**/{destroy_service,delete_service}.rb', base: root_path).sort.each do |path|
            namespace = path
              .sub(%r{\A(?:ee/)?app/services/(?:ee/)?}, '')
              .sub(%r{/(?:destroy|delete)_service\.rb\z}, '')
            next if EXCLUDED_NAMESPACES.include?(namespace)

            table = TABLE_OVERRIDES.fetch(namespace, namespace.tr('/', '_'))
            unless File.exist?(File.join(root_path, 'db', 'docs', "#{table}.yml"))
              unaccounted << namespace
              next
            end

            service = service_class_name(namespace, File.basename(path, '.rb'))
            services = (tables[table] ||= [])
            services << service unless services.include?(service)
          end

          @unaccounted_namespaces = unaccounted.uniq.sort.freeze
          @tables_to_services = tables.freeze
        end

        def root_path
          File.expand_path('../../..', __dir__)
        end

        def service_class_name(namespace, file_name)
          (namespace.split('/') + [file_name]).map do |segment|
            segment.split('_').map(&:capitalize).join
          end.join('::')
        end
      end
    end
  end
end
