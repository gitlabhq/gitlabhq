# frozen_string_literal: true

module Onboarding
  module FeatureLibrary
    module Catalog
      # Feature catalog Explore page content for the group sidebar.
      #
      # Adding a paid group nav item? ee/spec/lib/onboarding/feature_library/catalog_drift_spec.rb
      # fails until it has a NavItem here:
      # - item_id, category: the nav item's id and the super sidebar menu it renders under.
      # - title, description, icon: wrap the nav item's own strings in N_(), so no new msgids are needed.
      # - tier, licensed_features: the licensed features that gate the nav item, and their lowest plan.
      # - docs_path: the feature's page under doc/, with an optional #anchor for a section.
      # - shown_on_deployments: only set to limit where the Explore pages show the entry.
      # Growth (@gitlab-org/growth/engineers) reviews catalog changes.
      module GroupPanel
        # Ordered by super sidebar category, as in Catalog::CATEGORIES.
        NAV_ITEMS = [
          # Manage
          NavItem.new(
            item_id: :members, panel: :group, category: :manage_menu, tier: :free,
            title: N_('Members'), description: N_('Control who has access to your group and what they can do'),
            icon: 'users', docs_path: 'user/project/members/_index.md', shown_on_deployments: [:saas],
            enhancements: {
              premium: N_('FeatureLibrary|Unlimited licensed users'),
              ultimate: N_('FeatureLibrary|Add custom roles, and invite guests at no cost')
            }
          ),
          NavItem.new(
            item_id: :labels, panel: :group, category: :manage_menu, tier: :free,
            title: N_('Labels'),
            description: N_('Organize and categorize work across your group with consistent labels'),
            icon: 'labels', docs_path: 'user/project/labels.md',
            enhancements: {
              premium: N_('FeatureLibrary|Use scoped labels so only one value in a set applies at a time')
            }
          ),

          # Plan
          NavItem.new(
            item_id: :group_issue_list, panel: :group, category: :plan_menu, tier: :free,
            title: N_('WorkItem|Work items'), description: N_('Plan, track, and manage work in one place'),
            icon: 'work-items', docs_path: 'user/work_items/_index.md',
            enhancements: {
              premium: N_('FeatureLibrary|Add epics, weights, multiple assignees, and custom fields'),
              ultimate: N_('FeatureLibrary|Add objectives, key results, requirements, test cases, and health status')
            }
          ),
          # The nav says "Issue board" until multiple boards are licensed; the card promotes them.
          NavItem.new(
            item_id: :issue_boards, panel: :group, category: :plan_menu, tier: :free,
            title: N_('Issue boards'), description: N_('Visualize and manage work with kanban-style boards'),
            icon: 'work-item-issue-board', docs_path: 'user/project/issue_board.md',
            enhancements: { premium: N_('FeatureLibrary|Create multiple boards with scoped lists and epic swimlanes') }
          ),
          NavItem.new(
            item_id: :epic_boards, panel: :group, category: :plan_menu, tier: :premium, licensed_features: [:epics],
            title: N_('Epic boards'),
            description: N_('Visualize epic workflow and manage progress using kanban-style boards'),
            icon: 'work-item-epic-board', docs_path: 'user/group/epics/epic_boards.md'
          ),
          NavItem.new(
            item_id: :roadmap, panel: :group, category: :plan_menu, tier: :premium, licensed_features: [:epics],
            title: N_('Roadmap'),
            description: N_("Plan and communicate your group's strategic direction with a visual timeline"),
            icon: 'roadmap', docs_path: 'user/group/roadmap/_index.md'
          ),
          NavItem.new(
            item_id: :milestones, panel: :group, category: :plan_menu, tier: :free,
            title: N_('Milestones'), description: N_('Plan releases and group work into time-based phases'),
            icon: 'milestone', docs_path: 'user/project/milestones/_index.md',
            enhancements: { premium: N_('FeatureLibrary|See progress with burndown and burnup charts') }
          ),
          NavItem.new(
            item_id: :iterations, panel: :group, category: :plan_menu, tier: :premium,
            licensed_features: [:iterations],
            title: N_('Iterations'), description: N_('Group issues into time-boxed cycles to plan and track sprints'),
            icon: 'iteration', docs_path: 'user/group/iterations/_index.md'
          ),
          NavItem.new(
            item_id: :group_wiki, panel: :group, category: :plan_menu, tier: :premium,
            licensed_features: [:group_wikis],
            title: N_('Wiki'), description: N_('Create and manage documentation'),
            icon: 'book', docs_path: 'user/project/wiki/group.md'
          ),

          # AI
          NavItem.new(
            item_id: :ai_flows, panel: :group, category: :duo_agents_menu, tier: :add_on,
            title: N_('AICatalog|Flows'), description: N_('Manage AI flows'),
            icon: 'flow-ai', docs_path: 'user/duo_agent_platform/flows/_index.md'
          ),
          NavItem.new(
            item_id: :governance, panel: :group, category: :duo_agents_menu, tier: :premium,
            licensed_features: [:ai_chat, :ai_features],
            title: N_('Governance'),
            description: N_('AiGovernance|Monitor and control AI agent activity across your group'),
            icon: 'tanuki-ai', docs_path: 'user/ai-governance/_index.md'
          ),

          # Code
          NavItem.new(
            item_id: :group_merge_request_list, panel: :group, category: :code_menu, tier: :free,
            title: N_('Merge requests'), description: N_('Collaborate on code changes with built-in review tools'),
            icon: 'merge-request', docs_path: 'user/project/merge_requests/_index.md',
            enhancements: {
              ultimate: N_('FeatureLibrary|Block merges when a scan finds a vulnerability or a disallowed license')
            }
          ),

          # Secure
          NavItem.new(
            item_id: :security_dashboard, panel: :group, category: :secure_menu, tier: :ultimate,
            licensed_features: [:security_dashboard],
            title: N_('Security dashboard'), description: N_('View security findings and trends'),
            icon: 'shield', docs_path: 'user/application_security/security_dashboard/_index.md'
          ),
          NavItem.new(
            item_id: :vulnerability_report, panel: :group, category: :secure_menu, tier: :ultimate,
            licensed_features: [:security_dashboard],
            title: N_('Vulnerability report'), description: N_('Monitor and address security vulnerabilities'),
            icon: 'review-warning', docs_path: 'user/application_security/vulnerability_report/_index.md'
          ),
          NavItem.new(
            item_id: :security_inventory, panel: :group, category: :secure_menu, tier: :ultimate,
            licensed_features: [:security_inventory],
            title: N_('Security inventory'), description: N_('Inventory of security assets'),
            icon: 'security-inventory', docs_path: 'user/application_security/security_inventory/_index.md'
          ),
          NavItem.new(
            item_id: :dependency_list, panel: :group, category: :secure_menu, tier: :ultimate,
            licensed_features: [:security_dashboard],
            title: N_('Dependency list'),
            description: N_('Monitor open source libraries and their known vulnerabilities'),
            icon: 'dependency-list', docs_path: 'user/application_security/dependency_list/_index.md'
          ),
          NavItem.new(
            item_id: :audit_events, panel: :group, category: :secure_menu, tier: :premium,
            licensed_features: [:audit_events],
            title: N_('Audit events'), description: N_('See a complete record of all changes and access events'),
            icon: 'audit-events', docs_path: 'user/compliance/audit_events.md'
          ),
          NavItem.new(
            item_id: :compliance, panel: :group, category: :secure_menu, tier: :premium,
            licensed_features: [:group_level_compliance_dashboard],
            title: N_('Compliance center'), description: N_('Monitor and enforce compliance status and reports'),
            icon: 'compliance', docs_path: 'user/compliance/compliance_center/_index.md'
          ),
          NavItem.new(
            item_id: :scan_policies, panel: :group, category: :secure_menu, tier: :ultimate,
            licensed_features: [:security_orchestration_policies],
            title: N_('Policies'), description: N_('Set rules to protect your projects and data'),
            icon: 'policy', docs_path: 'user/application_security/policies/_index.md'
          ),
          NavItem.new(
            item_id: :credentials, panel: :group, category: :secure_menu, tier: :ultimate,
            licensed_features: [:credentials_inventory],
            title: N_('Credentials'), description: N_('Manage group credentials inventory'),
            icon: 'credentials', docs_path: 'administration/credentials_inventory.md', shown_on_deployments: [:saas]
          ),
          NavItem.new(
            item_id: :configuration, panel: :group, category: :secure_menu, tier: :ultimate,
            licensed_features: [:security_attributes, :security_scan_profiles],
            title: N_('Security configuration'), description: N_('Configure security scanning and settings'),
            icon: 'secrets-manager',
            docs_path: 'user/application_security/configuration/security_configuration_profiles.md'
          ),

          # Deploy
          NavItem.new(
            item_id: :virtual_registry, panel: :group, category: :deploy_menu, tier: :premium,
            licensed_features: [:packages_virtual_registry, :container_virtual_registry],
            title: N_('Virtual registry'), description: N_('Proxy and cache packages from upstream registries'),
            icon: 'archive', docs_path: 'user/packages/virtual_registry/_index.md'
          ),

          # Analyze
          NavItem.new(
            item_id: :analytics_dashboards, panel: :group, category: :analyze_menu, tier: :premium,
            licensed_features: [:group_level_analytics_dashboard],
            title: N_('Analytics dashboards'),
            description: N_('Create, manage, and measure custom analytics dashboards'),
            icon: 'chart', docs_path: 'user/analytics/analytics_dashboards.md'
          ),
          NavItem.new(
            item_id: :cycle_analytics, panel: :group, category: :analyze_menu, tier: :premium,
            licensed_features: [:cycle_analytics_for_groups],
            title: N_('Value stream analytics'), description: N_('Analyze value stream and cycle time'),
            icon: 'value-stream-analytics', docs_path: 'user/group/value_stream_analytics/_index.md'
          ),
          # Ultimate until Premium pipeline analytics ships (group_ci_cd_analytics_pipelines_ff).
          NavItem.new(
            item_id: :ci_cd_analytics, panel: :group, category: :analyze_menu, tier: :ultimate,
            licensed_features: [:group_ci_cd_analytics_releases],
            title: N_('CI/CD analytics'), description: N_('Analyze CI/CD pipeline metrics and performance'),
            icon: 'cicd-analytics', docs_path: 'user/project/releases/_index.md#release-metrics'
          ),
          NavItem.new(
            item_id: :contribution_analytics, panel: :group, category: :analyze_menu, tier: :premium,
            licensed_features: [:contribution_analytics],
            title: N_('Contribution analytics'), description: N_('Track and view member contributions and activity'),
            icon: 'contributor-analytics', docs_path: 'user/group/contribution_analytics/_index.md',
            shown_on_deployments: [:saas]
          ),
          NavItem.new(
            item_id: :devops_adoption, panel: :group, category: :analyze_menu, tier: :ultimate,
            licensed_features: [:group_level_devops_adoption],
            title: N_('DevOps adoption'), description: N_('Measure DevOps adoption across the group'),
            icon: 'devops-adoption', docs_path: 'user/group/devops_adoption/_index.md'
          ),
          NavItem.new(
            item_id: :insights, panel: :group, category: :analyze_menu, tier: :ultimate,
            licensed_features: [:insights],
            title: N_('Insights'), description: N_('View insights and build custom charts and reports'),
            icon: 'bulb', docs_path: 'user/project/insights/_index.md'
          ),
          NavItem.new(
            item_id: :issues_analytics, panel: :group, category: :analyze_menu, tier: :premium,
            licensed_features: [:issues_analytics],
            title: N_('Issue analytics'), description: N_('Track issue metrics, trends, and throughput'),
            icon: 'work-item-issue-analytics', docs_path: 'user/group/issues_analytics/_index.md'
          ),
          NavItem.new(
            item_id: :productivity_analytics, panel: :group, category: :analyze_menu, tier: :premium,
            licensed_features: [:productivity_analytics],
            title: N_('Productivity analytics'), description: N_('Measure team productivity metrics'),
            icon: 'productivity-analytics', docs_path: 'user/analytics/productivity_analytics.md'
          ),
          NavItem.new(
            item_id: :repository_analytics, panel: :group, category: :analyze_menu, tier: :premium,
            licensed_features: [:group_coverage_reports],
            title: N_('Repository analytics'), description: N_('Analyze repository coverage, statistics, and metrics'),
            icon: 'repository-analytics', docs_path: 'user/group/repositories_analytics/_index.md'
          )
        ].freeze

        CAPABILITIES = [
          Capability.new(
            id: :merge_controls, panel: :group, tier: :premium,
            title: N_('FeatureLibrary|Merge controls'),
            description: N_(
              'FeatureLibrary|Require approvals, enforce Code Owners, and queue merges with merge trains'
            ),
            icon: 'code', docs_path: 'ci/pipelines/merge_trains.md', supersedes_nav_items: [:group_merge_request_list]
          ),
          Capability.new(
            id: :runner_limits, panel: :group, tier: :premium,
            title: N_('FeatureLibrary|Runners'),
            description: N_('FeatureLibrary|Register up to 1,000 runners, and run up to 1,500 jobs per pipeline'),
            icon: 'rocket', docs_path: 'ci/runners/_index.md', shown_on_deployments: [:saas]
          ),
          Capability.new(
            id: :compute_minutes_premium, panel: :group, tier: :premium,
            title: N_('FeatureLibrary|Compute minutes'),
            description: N_('FeatureLibrary|Get %{plan_minutes} compute minutes a month, ' \
              'up from %{base_minutes} minutes on %{base_plan}'),
            description_variables: %i[plan_minutes base_minutes base_plan],
            icon: 'rocket', docs_path: 'ci/pipelines/compute_minutes.md', shown_on_deployments: [:saas]
          ),
          Capability.new(
            id: :advanced_sast, panel: :group, tier: :ultimate,
            title: N_('FeatureLibrary|Advanced SAST'),
            description: N_('FeatureLibrary|Scan across files and functions with static application security testing'),
            icon: 'shield', docs_path: 'user/application_security/sast/gitlab_advanced_sast.md',
            supersedes_nav_items: [:configuration]
          ),
          Capability.new(
            id: :dependency_scanning, panel: :group, tier: :ultimate,
            title: N_('FeatureLibrary|Dependency scanning'),
            description: N_('FeatureLibrary|Find known vulnerabilities in the packages your code depends on'),
            icon: 'shield', docs_path: 'user/application_security/dependency_scanning/_index.md',
            supersedes_nav_items: [:dependency_list]
          ),
          Capability.new(
            id: :compute_minutes_ultimate, panel: :group, tier: :ultimate,
            title: N_('FeatureLibrary|Compute minutes'),
            description: N_('FeatureLibrary|Get %{plan_minutes} compute minutes a month, ' \
              'up from %{base_minutes} minutes on %{base_plan}'),
            description_variables: %i[plan_minutes base_minutes base_plan],
            icon: 'rocket', docs_path: 'ci/pipelines/compute_minutes.md', shown_on_deployments: [:saas]
          ),
          Capability.new(
            id: :duo_agent_platform, panel: :group, tier: :add_on,
            title: N_('FeatureLibrary|GitLab Duo Agent Platform'),
            description: N_('FeatureLibrary|Run AI agents and flows across your work, paid for with GitLab Credits'),
            icon: 'tanuki-ai', docs_path: 'user/duo_agent_platform/_index.md', supersedes_nav_items: [:ai_flows]
          ),
          Capability.new(
            id: :secrets_manager, panel: :group, tier: :add_on,
            title: N_('FeatureLibrary|Secrets manager'),
            description: N_('FeatureLibrary|Store and manage secrets in GitLab, paid for with GitLab Credits'),
            icon: 'secrets-manager', docs_path: 'ci/secrets/secrets_manager/_index.md'
          )
        ].freeze
      end
    end
  end
end
