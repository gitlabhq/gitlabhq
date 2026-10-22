# frozen_string_literal: true

module Onboarding
  module FeatureLibrary
    module Catalog
      # Feature catalog Explore page content for the project sidebar.
      #
      # Adding a paid project nav item? ee/spec/lib/onboarding/feature_library/catalog_drift_spec.rb
      # fails until it has a NavItem here:
      # - item_id, category: the nav item's id and the super sidebar menu it renders under.
      # - title, description, icon: wrap the nav item's own strings in N_(), so no new msgids are needed.
      # - tier, licensed_features: the licensed features that gate the nav item, and their lowest plan.
      # - docs_path: the feature's page under doc/.
      # - shown_on_deployments: only set to limit where the Explore pages show the entry.
      # Growth (@gitlab-org/growth/engineers) reviews catalog changes.
      module ProjectPanel
        # Ordered by super sidebar category, as in Catalog::CATEGORIES.
        NAV_ITEMS = [
          # Manage
          NavItem.new(
            item_id: :members, panel: :project, category: :manage_menu, tier: :free,
            title: N_('Members'), description: N_('Control who has access to your project and what they can do'),
            icon: 'users', docs_path: 'user/project/members/_index.md', shown_on_deployments: [:saas],
            enhancements: {
              premium: N_('FeatureLibrary|Unlimited licensed users'),
              ultimate: N_('FeatureLibrary|Add custom roles, and invite guests at no cost')
            }
          ),
          NavItem.new(
            item_id: :labels, panel: :project, category: :manage_menu, tier: :free,
            title: N_('Labels'),
            description: N_('Organize and categorize work across your project with consistent labels'),
            icon: 'labels', docs_path: 'user/project/labels.md',
            enhancements: {
              premium: N_('FeatureLibrary|Use scoped labels so only one value in a set applies at a time')
            }
          ),

          # Plan
          NavItem.new(
            item_id: :project_issue_list, panel: :project, category: :plan_menu, tier: :free,
            title: N_('WorkItem|Work items'), description: N_('Plan, track, and manage work in one place'),
            icon: 'work-items', docs_path: 'user/work_items/_index.md',
            enhancements: {
              premium: N_('FeatureLibrary|Add weights, multiple assignees, and custom fields'),
              ultimate: N_('FeatureLibrary|Add objectives, key results, requirements, test cases, and health status')
            }
          ),
          NavItem.new(
            item_id: :boards, panel: :project, category: :plan_menu, tier: :free,
            title: N_('Issue boards'), description: N_('Visualize and manage work with kanban-style boards'),
            icon: 'work-item-issue-board', docs_path: 'user/project/issue_board.md',
            enhancements: { premium: N_('FeatureLibrary|Create multiple boards with scoped lists and epic swimlanes') }
          ),
          NavItem.new(
            item_id: :milestones, panel: :project, category: :plan_menu, tier: :free,
            title: N_('Milestones'), description: N_('Plan releases and group work into time-based phases'),
            icon: 'milestone', docs_path: 'user/project/milestones/_index.md',
            enhancements: { premium: N_('FeatureLibrary|See progress with burndown and burnup charts') }
          ),
          NavItem.new(
            item_id: :iterations, panel: :project, category: :plan_menu, tier: :premium,
            licensed_features: [:iterations],
            title: N_('Iterations'), description: N_('Group issues into time-boxed cycles to plan and track sprints'),
            icon: 'iteration', docs_path: 'user/group/iterations/_index.md'
          ),
          NavItem.new(
            item_id: :requirements, panel: :project, category: :plan_menu, tier: :ultimate,
            licensed_features: [:requirements],
            title: N_('Requirements'), description: N_('Set criteria to check your products against'),
            icon: 'requirements', docs_path: 'user/project/requirements/_index.md'
          ),

          # AI
          NavItem.new(
            item_id: :ai_flows, panel: :project, category: :duo_agents_menu, tier: :add_on,
            title: N_('AICatalog|Flows'), description: N_('Manage AI flows'),
            icon: 'flow-ai', docs_path: 'user/duo_agent_platform/flows/_index.md'
          ),
          NavItem.new(
            item_id: :governance, panel: :project, category: :duo_agents_menu, tier: :premium,
            licensed_features: [:ai_chat, :ai_features],
            title: N_('Governance'),
            description: N_('AiGovernance|Monitor and control AI agent activity in your project'),
            icon: 'tanuki-ai', docs_path: 'user/ai-governance/_index.md'
          ),

          # Code
          NavItem.new(
            item_id: :project_merge_request_list, panel: :project, category: :code_menu, tier: :free,
            title: N_('Merge requests'), description: N_('Collaborate on code changes with built-in review tools'),
            icon: 'merge-request', docs_path: 'user/project/merge_requests/_index.md',
            enhancements: {
              ultimate: N_('FeatureLibrary|Block merges when a scan finds a vulnerability or a disallowed license')
            }
          ),
          NavItem.new(
            item_id: :file_locks, panel: :project, category: :code_menu, tier: :premium,
            licensed_features: [:file_locks],
            title: N_('Locked files'), description: N_('Manage file locks to prevent conflicting changes'),
            icon: 'doc-locked', docs_path: 'user/project/file_lock.md'
          ),

          # Build
          NavItem.new(
            item_id: :pipelines, panel: :project, category: :build_menu, tier: :free,
            title: N_('Pipelines'), description: N_('Automate your build and deployment process'),
            icon: 'pipeline', docs_path: 'ci/pipelines/_index.md',
            enhancements: {
              premium: N_('FeatureLibrary|See multi-project pipeline graphs and subscribe to upstream pipelines')
            }
          ),
          NavItem.new(
            item_id: :test_cases, panel: :project, category: :build_menu, tier: :ultimate,
            licensed_features: [:quality_management],
            title: N_('Test cases'), description: N_('Define and manage test cases for your project'),
            icon: 'work-item-test-case', docs_path: 'ci/test_cases/_index.md'
          ),

          # Secure
          NavItem.new(
            item_id: :dashboard, panel: :project, category: :secure_menu, tier: :ultimate,
            licensed_features: [:security_dashboard],
            title: N_('Security dashboard'), description: N_('View security findings and trends'),
            icon: 'shield', docs_path: 'user/application_security/security_dashboard/_index.md'
          ),
          NavItem.new(
            item_id: :vulnerability_report, panel: :project, category: :secure_menu, tier: :ultimate,
            licensed_features: [:security_dashboard],
            title: N_('Vulnerability report'), description: N_('Monitor and address security vulnerabilities'),
            icon: 'review-warning', docs_path: 'user/application_security/vulnerability_report/_index.md'
          ),
          NavItem.new(
            item_id: :dependency_list, panel: :project, category: :secure_menu, tier: :ultimate,
            licensed_features: [:dependency_scanning],
            title: N_('Dependency list'),
            description: N_('Monitor open source libraries and their known vulnerabilities'),
            icon: 'dependency-list', docs_path: 'user/application_security/dependency_list/_index.md'
          ),
          NavItem.new(
            item_id: :audit_events, panel: :project, category: :secure_menu, tier: :premium,
            licensed_features: [:audit_events],
            title: N_('Audit events'), description: N_('See a complete record of all changes and access events'),
            icon: 'audit-events', docs_path: 'user/compliance/audit_events.md'
          ),
          NavItem.new(
            item_id: :compliance, panel: :project, category: :secure_menu, tier: :ultimate,
            licensed_features: [:project_level_compliance_dashboard],
            title: N_('Compliance center'), description: N_('Monitor and enforce compliance status and reports'),
            icon: 'compliance', docs_path: 'user/compliance/compliance_center/_index.md'
          ),
          NavItem.new(
            item_id: :scan_policies, panel: :project, category: :secure_menu, tier: :ultimate,
            licensed_features: [:security_orchestration_policies],
            title: N_('Policies'), description: N_('Set rules to protect your projects and data'),
            icon: 'policy', docs_path: 'user/application_security/policies/_index.md'
          ),
          NavItem.new(
            item_id: :on_demand_scans, panel: :project, category: :secure_menu, tier: :ultimate,
            licensed_features: [:security_on_demand_scans],
            title: N_('OnDemandScans|On-demand scans'),
            description: N_('Run security scans on demand against any branch or environment'),
            icon: 'on-demand-scan', docs_path: 'user/application_security/dast/on-demand_scan.md'
          ),

          # Operate
          NavItem.new(
            item_id: :environments, panel: :project, category: :operations_menu, tier: :free,
            title: N_('Environments'), description: N_('Manage your staging and production deployments'),
            icon: 'environment', docs_path: 'ci/environments/_index.md',
            enhancements: { premium: N_('FeatureLibrary|Protect environments and require approval before deploying') }
          ),

          # Monitor
          NavItem.new(
            item_id: :incidents, panel: :project, category: :monitor_menu, tier: :free,
            title: N_('Incidents'), description: N_('Manage incident response and resolution'),
            icon: 'work-item-incident', docs_path: 'operations/incident_management/incidents.md',
            enhancements: {
              premium: N_('FeatureLibrary|Route incidents through on-call schedules and escalation policies')
            }
          ),
          NavItem.new(
            item_id: :on_call_schedules, panel: :project, category: :monitor_menu, tier: :premium,
            licensed_features: [:oncall_schedules],
            title: N_('On-call Schedules'),
            description: N_('Define on-call rotations to ensure the right people are alerted'),
            icon: 'on-call-schedules', docs_path: 'operations/incident_management/oncall_schedules.md'
          ),
          NavItem.new(
            item_id: :escalation_policies, panel: :project, category: :monitor_menu, tier: :premium,
            licensed_features: [:escalation_policies],
            title: N_('Escalation Policies'),
            description: N_('Set escalation rules to ensure alerts reach the right responders'),
            icon: 'escalation-policy', docs_path: 'operations/incident_management/escalation_policies.md'
          ),

          # Analyze
          NavItem.new(
            item_id: :dashboards_analytics, panel: :project, category: :analyze_menu, tier: :premium,
            licensed_features: [:project_level_analytics_dashboard],
            title: N_('Analytics dashboards'),
            description: N_('Create, manage, and measure custom analytics dashboards'),
            icon: 'chart', docs_path: 'user/analytics/analytics_dashboards.md'
          ),
          NavItem.new(
            item_id: :cycle_analytics, panel: :project, category: :analyze_menu, tier: :free,
            title: N_('Value stream analytics'), description: N_('Analyze value stream and cycle time'),
            icon: 'value-stream-analytics', docs_path: 'user/group/value_stream_analytics/_index.md',
            enhancements: {
              premium: N_('FeatureLibrary|Build custom value streams with your own stages'),
              ultimate: N_('FeatureLibrary|Add DORA metrics to your value streams')
            }
          ),
          NavItem.new(
            item_id: :code_review, panel: :project, category: :analyze_menu, tier: :premium,
            licensed_features: [:code_review_analytics],
            title: N_('Code review analytics'),
            description: N_('Measure code review efficiency and merge request throughput'),
            icon: 'code-review-analytics', docs_path: 'user/analytics/code_review_analytics.md'
          ),
          NavItem.new(
            item_id: :issues, panel: :project, category: :analyze_menu, tier: :premium,
            licensed_features: [:issues_analytics],
            title: N_('Issue analytics'), description: N_('Track issue metrics, trends, and throughput'),
            icon: 'work-item-issue-analytics', docs_path: 'user/group/issues_analytics/_index.md'
          ),
          NavItem.new(
            item_id: :insights, panel: :project, category: :analyze_menu, tier: :ultimate,
            licensed_features: [:insights],
            title: N_('Insights'), description: N_('View insights and build custom charts and reports'),
            icon: 'bulb', docs_path: 'user/project/insights/_index.md'
          )
        ].freeze

        CAPABILITIES = [
          Capability.new(
            id: :merge_controls, panel: :project, tier: :premium,
            title: N_('FeatureLibrary|Merge controls'),
            description: N_(
              'FeatureLibrary|Require approvals, enforce Code Owners, and queue merges with merge trains'
            ),
            icon: 'code', docs_path: 'ci/pipelines/merge_trains.md',
            supersedes_nav_items: [:project_merge_request_list]
          ),
          Capability.new(
            id: :protected_environments, panel: :project, tier: :premium,
            title: N_('Environments'),
            description: N_('FeatureLibrary|Protect environments and require approval before deploying'),
            icon: 'cloud-pod', docs_path: 'ci/environments/protected_environments.md',
            supersedes_nav_items: [:environments]
          ),
          Capability.new(
            id: :compute_minutes_premium, panel: :project, tier: :premium,
            title: N_('FeatureLibrary|Compute minutes'),
            description: N_('FeatureLibrary|Get %{plan_minutes} compute minutes a month, ' \
              'up from %{base_minutes} minutes on %{base_plan}'),
            description_variables: %i[plan_minutes base_minutes base_plan],
            icon: 'rocket', docs_path: 'ci/pipelines/compute_minutes.md', shown_on_deployments: [:saas]
          ),
          Capability.new(
            id: :advanced_sast, panel: :project, tier: :ultimate,
            title: N_('FeatureLibrary|Advanced SAST'),
            description: N_('FeatureLibrary|Scan across files and functions with static application security testing'),
            icon: 'shield', docs_path: 'user/application_security/sast/gitlab_advanced_sast.md'
          ),
          Capability.new(
            id: :dependency_scanning, panel: :project, tier: :ultimate,
            title: N_('FeatureLibrary|Dependency scanning'),
            description: N_('FeatureLibrary|Find known vulnerabilities in the packages your code depends on'),
            icon: 'shield', docs_path: 'user/application_security/dependency_scanning/_index.md',
            supersedes_nav_items: [:dependency_list]
          ),
          Capability.new(
            id: :compute_minutes_ultimate, panel: :project, tier: :ultimate,
            title: N_('FeatureLibrary|Compute minutes'),
            description: N_('FeatureLibrary|Get %{plan_minutes} compute minutes a month, ' \
              'up from %{base_minutes} minutes on %{base_plan}'),
            description_variables: %i[plan_minutes base_minutes base_plan],
            icon: 'rocket', docs_path: 'ci/pipelines/compute_minutes.md', shown_on_deployments: [:saas]
          ),
          Capability.new(
            id: :duo_agent_platform, panel: :project, tier: :add_on,
            title: N_('FeatureLibrary|GitLab Duo Agent Platform'),
            description: N_('FeatureLibrary|Run AI agents and flows across your work, paid for with GitLab Credits'),
            icon: 'tanuki-ai', docs_path: 'user/duo_agent_platform/_index.md', supersedes_nav_items: [:ai_flows]
          ),
          Capability.new(
            id: :secrets_manager, panel: :project, tier: :add_on,
            title: N_('FeatureLibrary|Secrets manager'),
            description: N_('FeatureLibrary|Store and manage secrets in GitLab, paid for with GitLab Credits'),
            icon: 'secrets-manager', docs_path: 'ci/secrets/secrets_manager/_index.md'
          )
        ].freeze
      end
    end
  end
end
