---
stage: none
group: none
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>"
title: Event store event index
---

<!--
DO NOT EDIT THIS PAGE DIRECTLY

This page is automatically generated from the YAML files in `data/events/`
using the template at `data/events/templates/_event_template.md.erb`
and the Rake task at `lib/tasks/gitlab/docs/compile_events.rake`.

To add or update an event, edit the corresponding YAML file in `data/events/`.
Then regenerate this page by running:

  bin/rake gitlab:docs:compile_events

To verify this page is up to date, run:

  bin/rake gitlab:docs:check_events
-->

This page lists all domain events published through the
[GitLab EventStore](_index.md), grouped by domain.

Each event is defined in `app/events/` and carries a JSON Schema-validated payload.
To find subscribers, search the subscription files under
`lib/gitlab/event_store/subscriptions/` and `ee/lib/gitlab/event_store/subscriptions/`.

<!-- vale off -->

## Ai

| Event | Feature category | Edition | Description |
|-------|-----------------|---------|-------------|
| `Ai::ActiveContext::Code::CreateEnabledNamespaceEvent` | `global_search` | EE | Published to trigger creation of Ai::ActiveContext::Code::EnabledNamespace records for namespaces eligible for code indexing. Re-emitted by the subscriber worker to continue batched processing across event invocations. |
| `Ai::ActiveContext::Code::MarkRepositoryAsPendingDeletionEvent` | `global_search` | EE | Published to mark Ai::ActiveContext::Code::Repository records as pending deletion when their enabled namespace is gone, Duo features are disabled, or there has been no recent activity. Re-emitted by the subscriber worker to continue batched processing. |
| `Ai::ActiveContext::Code::MarkRepositoryAsReadyEvent` | `global_search` | EE | Published to mark Ai::ActiveContext::Code::Repository records whose embedding indexing has completed as ready, by checking the search index for the presence of expected embedding fields. |
| `Ai::ActiveContext::Code::ProcessInvalidEnabledNamespaceEvent` | `global_search` | EE | Published to remove Ai::ActiveContext::Code::EnabledNamespace records that are no longer eligible (e.g. expired SaaS subscriptions or instances without AI features). Re-emitted by the subscriber worker to continue batched processing. |
| `Ai::ActiveContext::Code::ProcessPendingEnabledNamespaceEvent` | `global_search` | EE | Published to process the next pending Ai::ActiveContext::Code::EnabledNamespace by enrolling its eligible projects as Ai::ActiveContext::Code::Repository records. Re-emitted by the subscriber worker while pending namespaces remain. |
| `Ai::DuoWorkflows::WorkflowStartedEvent` | `duo_agent_platform` | EE | Published when a Duo workflow first transitions to :running (the agent has begun executing). Only emitted for messaging-triggered workflows. Deferred via run_after_commit. |

## Analytics

| Event | Feature category | Edition | Description |
|-------|-----------------|---------|-------------|
| `Analytics::ClickHouseForAnalyticsEnabledEvent` | `value_stream_management` | EE | Published when the instance-wide setting `use_clickhouse_for_analytics` is toggled on, signalling that ClickHouse-backed analytics has just been enabled so downstream backfill jobs can run. |

## Ci

| Event | Feature category | Edition | Description |
|-------|-----------------|---------|-------------|
| `Ci::JobArtifactsDeletedEvent` | `job_artifacts` | CE | Published after a batch of CI job artifacts is deleted. Wrapped in Sidekiq::Worker.skipping_transaction_check so it can be emitted outside a transaction context. |
| `Ci::JobSecurityScanCompletedEvent` | `vulnerability_management` | EE | Published when a CI build that runs a security scan reaches a completed status, signalling that its security artifacts are ready to be ingested. |
| `Ci::PipelineCreatedEvent` | `continuous_integration` | CE | Published when a CI pipeline is successfully created and persisted. |
| `Ci::PipelineFinishedEvent` | `continuous_integration` | CE | Published when a CI pipeline transitions to a terminal state (success, failed, canceled, skipped, or manual). Deferred via run_after_commit, so it fires only after the status change is committed. |
| `Ci::Workloads::WorkloadFinishedEvent` | `continuous_integration` | CE | Published when a CI workload transitions to :finished or :failed. Deferred via run_after_commit. |

## Container Registry

| Event | Feature category | Edition | Description |
|-------|-----------------|---------|-------------|
| `ContainerRegistry::ImagePushedEvent` | `container_registry` | EE | Published when the container registry notifies GitLab of a successful image push, so subscribers (e.g. container scanning) can react to the new image. |

## GitLab

| Event | Feature category | Edition | Description |
|-------|-----------------|---------|-------------|
| `Gitlab::FeatureFlags::FeatureFlagModifiedEvent` | `feature_flags` | CE | Published when a feature flag is modified via `Feature.enable()` or `Feature.disable()`. The event is emitted whenever Flipper confirms a state change occurred, indicating a global enable/disable, or an actor being added/removed from the feature flag. The operation field indicates the type of change - `enabled_globally`, `disabled_globally`, `enabled_actor`, or `disabled_actor`. For actor operations, the actor field contains the specific actor's flipper ID (for example, `User:123`, `Group:456`). |

## GitLab Subscriptions

| Event | Feature category | Edition | Description |
|-------|-----------------|---------|-------------|
| `GitlabSubscriptions::RenewedEvent` | `subscription_management` | CE | Published when a GitLab subscription is renewed. Fires only on genuine renewals — both start_date and end_date must change in the same update, with the new start_date >= the previous end_date. Deferred via run_after_commit. |

## Groups

| Event | Feature category | Edition | Description |
|-------|-----------------|---------|-------------|
| `Groups::GroupDeletedEvent` | `groups_and_projects` | CE | Published after a group and all its contents are permanently destroyed. |
| `Groups::GroupTransferedEvent` | `groups_and_projects` | CE | Published after a group is transferred to a different parent namespace. |

## Mcp

| Event | Feature category | Edition | Description |
|-------|-----------------|---------|-------------|
| `Mcp::ServerSettingsChangedEvent` | `mcp_server` | EE | Published when a group's MCP server namespace settings (e.g. `mcp_server_enabled`) change, so consumers such as the MCP server cache can be refreshed. |

## Members

| Event | Feature category | Edition | Description |
|-------|-----------------|---------|-------------|
| `Members::AcceptedInviteEvent` | `user_management` | CE | Published when a user accepts a membership invitation to a group or project. |
| `Members::DestroyedEvent` | `user_management` | CE | Published after a member record is removed from a group or project. Fires once per user per destroy operation; not published on recursive cascades (for example, when a parent group destroy removes child memberships). Deferred via run_after_commit_or_now. |
| `Members::MembersAddedEvent` | `user_management` | CE | Published after one or more members are added to a group or project. A single event carries all successfully created user IDs; skipped entirely when every invited user fails validation. |
| `Members::MembershipModifiedByAdminEvent` | `seat_cost_management` | EE | Published when an admin creates or promotes a member to a billable role while member-promotion-management is enabled, so pending approval workflows can be processed. |
| `Members::UpdatedEvent` | `user_management` | CE | Published after one or more member access levels are updated. Skipped on no-op updates (empty members array). |

## Merge Requests

| Event | Feature category | Edition | Description |
|-------|-----------------|---------|-------------|
| `MergeRequests::ApprovalsResetEvent` | `code_review_workflow` | EE | Published when existing approvals on a merge request are reset, typically because new commits were pushed or other state changes invalidated prior approvals. |
| `MergeRequests::ApprovedEvent` | `code_review_workflow` | CE | Published when a user approves a merge request. Fires only when the approving user is eligible (not the author, satisfies any approval rules), the MR is not already merged, and the approval record is persisted. |
| `MergeRequests::AutoMerge::TitleDescriptionUpdateEvent` | `code_review_workflow` | CE | Published when an MR title or description changes while auto-merge is enabled and the project has merge_request_title_regex configured. Does not fire for description-only changes unless EE Jira-key detection also triggers. |
| `MergeRequests::ClosedEvent` | `code_review_workflow` | EE | Published when a merge request is closed, so EE subscribers (such as security policy workers) can react to the state change. |
| `MergeRequests::CreatedEvent` | `code_review_workflow` | EE | Published when a new merge request is created and prepared, so EE subscribers can react to the new merge request. |
| `MergeRequests::DiscussionsResolvedEvent` | `code_review_workflow` | CE | Published when resolving a discussion brings an auto-merge-enabled MR to a fully resolved state (mergeable_discussions_state? becomes true). Does not fire on every resolution — only when the resolution unblocks auto-merge. |
| `MergeRequests::DraftNotePublishedEvent` | `code_review_workflow` | CE | Published when a draft note (pending review comment) is published on a merge request. |
| `MergeRequests::DraftStateChangeEvent` | `code_review_workflow` | CE | Published when an MR title update toggles the "Draft:" prefix and the draft status actually changes. Title updates that leave the draft state unchanged do not fire it. |
| `MergeRequests::ExternalStatusCheckPassedEvent` | `compliance_management` | EE | Published when an external status check response transitions to the passed state for a merge request. |
| `MergeRequests::MergeRequestPreparedEvent` | `code_review_workflow` | CE | Represents a merge request ref being prepared after a push. Carries the project, user, old/new revisions, and the ref name. Not currently published anywhere in the codebase. |
| `MergeRequests::MergeableEvent` | `code_review_workflow` | CE | Published when an asynchronous mergeability check completes with both auto_merge_enabled? and mergeability_checks_pass? true (typically after approvals become sufficient). |
| `MergeRequests::MergedEvent` | `code_review_workflow` | EE | Published when a merge request has been merged and post-merge processing runs, allowing EE subscribers (such as compliance, security policy, and audit workers) to react. |
| `MergeRequests::OverrideRequestedChangesStateEvent` | `code_review_workflow` | CE | Published when a reviewer's "requested changes" status is overridden on a merge request. |
| `MergeRequests::PipelineCreationCompletedEvent` | `code_review_workflow` | CE | Published when an asynchronous MR-scoped pipeline creation attempt finishes. `pipeline_id` is set if a `Ci::Pipeline` row was persisted, nil if creation produced no pipeline (workflow:rules dropped, missing CI config, etc.). Used to re-trigger auto-merge when no `Ci::Pipeline.after_transition` will fire. |
| `MergeRequests::ReopenedEvent` | `code_review_workflow` | EE | Published when a closed merge request is reopened, so EE subscribers can react to the state change. |
| `MergeRequests::UnblockedStateEvent` | `code_review_workflow` | CE | Published when the set of blocking merge requests changes (for example, a blocking MR is merged, unlinked, or added). Requires the :blocking_merge_requests feature on the target project, and only fires when the set actually differs from the previous state. |
| `MergeRequests::UpdatedEvent` | `code_review_workflow` | EE | Published when a merge request is updated, so EE subscribers can react to changes on the merge request. |
| `MergeRequests::ViolationsUpdatedEvent` | `security_policy_management` | EE | Published when scan result / approval policy violations on a merge request have been recalculated and persisted, so subscribers can refresh policy state. |

## Milestones

| Event | Feature category | Edition | Description |
|-------|-----------------|---------|-------------|
| `Milestones::MilestoneUpdatedEvent` | `team_planning` | CE | Published when a milestone's attributes (title, dates, etc.) are updated. Skipped for no-op saves; the updated_attributes payload lists which attributes actually changed. |

## Namespace Settings

| Event | Feature category | Edition | Description |
|-------|-----------------|---------|-------------|
| `NamespaceSettings::AiRelatedSettingsChangedEvent` | `ai_abstraction_layer` | EE | Published when a group's AI-related namespace settings (e.g. `experiment_features_enabled`) change, so consumers such as the LLM namespace access cache can be refreshed. |

## Namespaces

| Event | Feature category | Edition | Description |
|-------|-----------------|---------|-------------|
| `Namespaces::Groups::GroupArchivedEvent` | `groups_and_projects` | CE | Published when a group is archived. |
| `Namespaces::Groups::GroupPathChangedEvent` | `groups_and_projects` | CE | Published when a group's URL path is changed. Not fired for group updates that leave the path unchanged. Deferred via run_after_commit_or_now. |

## Organizations

| Event | Feature category | Edition | Description |
|-------|-----------------|---------|-------------|
| `Organizations::GroupTransferredEvent` | `organization` | CE | Published when a root group is transferred to a different organization. Fired once for the transferred group only — subscribers are responsible for traversing descendants if needed. Published via run_after_commit_or_now inside the transfer transaction, so it is never emitted on rollback. |

## Package Metadata

| Event | Feature category | Edition | Description |
|-------|-----------------|---------|-------------|
| `PackageMetadata::IngestedAdvisoryEvent` | `software_composition_analysis` | CE | Published once per advisory record after package security advisories are ingested. Only fires for advisories whose published_date is within the last 14 days (PUBLISHED_ADVISORY_INTERVAL); older advisories are ingested without an event. |

## Packages

| Event | Feature category | Edition | Description |
|-------|-----------------|---------|-------------|
| `Packages::PackageCreatedEvent` | `package_registry` | CE | Published after a package is created in the package registry. |

## Pages

| Event | Feature category | Edition | Description |
|-------|-----------------|---------|-------------|
| `Pages::Domains::PagesDomainCreatedEvent` | `pages` | CE | Published when a custom domain is successfully added to a GitLab Pages site. |
| `Pages::Domains::PagesDomainDeletedEvent` | `pages` | CE | Published when a custom domain is removed from a GitLab Pages site. |
| `Pages::Domains::PagesDomainUpdatedEvent` | `pages` | CE | Published when a custom GitLab Pages domain is updated, including on ACME-order retries that reset auto_ssl_failed (retries fire only when auto_ssl_enabled and auto_ssl_failed were both true before). |

## Project Authorizations

| Event | Feature category | Edition | Description |
|-------|-----------------|---------|-------------|
| `ProjectAuthorizations::AuthorizationsAddedEvent` | `permissions` | CE | Published after project authorization rows are inserted for one or more users. Multiple changes may be batched into a single event group. |
| `ProjectAuthorizations::AuthorizationsChangedEvent` | `permissions` | CE | Defined to signal project authorization access-level changes. Not currently published anywhere in the codebase; a subscriber exists in EE security_subscriptions.rb but no publish call has been added yet. |
| `ProjectAuthorizations::AuthorizationsRemovedEvent` | `permissions` | CE | Published after project authorization rows are deleted, but only for users who are truly removed — not for those whose access level merely changes (those users are excluded by comparing against authorizations being added in the same operation). Events are batched. |

## Projects

| Event | Feature category | Edition | Description |
|-------|-----------------|---------|-------------|
| `Projects::ComplianceFrameworkChangedEvent` | `compliance_management` | EE | Published when a compliance framework is added to or removed from a project. The event_type field indicates whether the framework was added or removed. |
| `Projects::ProjectArchivedEvent` | `groups_and_projects` | CE | Published when a project is archived. |
| `Projects::ProjectCreatedEvent` | `groups_and_projects` | CE | Published after a new project is successfully created. |
| `Projects::ProjectDeletedEvent` | `groups_and_projects` | CE | Published after a project and all its contents are permanently destroyed. |
| `Projects::ProjectFeaturesChangedEvent` | `groups_and_projects` | CE | Published when a project's feature availability settings change (for example, issues, wiki, CI enabled/disabled). Not published when ProjectFeature#previous_changes is blank. |
| `Projects::ProjectPathChangedEvent` | `source_code_management` | CE | Published when a project's URL path (slug) is renamed. |
| `Projects::ProjectTransferedEvent` | `groups_and_projects` | CE | Published after a project is transferred to a different namespace. |
| `Projects::ProjectVisibilityChangedEvent` | `groups_and_projects` | CE | Published when a project's visibility_level changes. Not published for updates that leave visibility unchanged. |
| `Projects::ReleasePublishedEvent` | `release_orchestration` | CE | Published when a release in waiting_for_publish_event state is made available, processed in batches of 100. Releases are stamped with release_published_at after the event fires. |
| `Projects::SecurityAttributeChangedEvent` | `security_asset_inventories` | EE | Published when a security attribute association is added to or removed from a project. The event_type field indicates whether the attribute was added or removed. |

## Repositories

| Event | Feature category | Edition | Description |
|-------|-----------------|---------|-------------|
| `Repositories::DefaultBranchChangedEvent` | `source_code_management` | CE | Published when the default branch of a repository changes. |
| `Repositories::KeepAroundRefsCreatedEvent` | `source_code_management` | CE | Published when keep-around refs are written to a repository to prevent commits from being garbage collected. Fires only when at least one non-nil SHA is provided (typically during pipeline creation). Wrapped in Sidekiq::Worker.skipping_transaction_check. |
| `Repositories::ProtectedBranchCreatedEvent` | `source_code_management` | CE | Published after a new branch protection rule is persisted. Fires for both project-level and group-level protected branches; the parent_type payload field distinguishes them. |
| `Repositories::ProtectedBranchDestroyedEvent` | `source_code_management` | CE | Published after a branch protection rule is removed. |
| `Repositories::RepositoryCreatedEvent` | `source_code_management` | CE | Published when a repository is created for a project or other container. |

## Sbom

| Event | Feature category | Edition | Description |
|-------|-----------------|---------|-------------|
| `Sbom::SbomIngestedEvent` | `software_composition_analysis` | EE | Published after an SBOM report has been ingested for a pipeline and at least one occurrence was recorded. Carries the `pipeline_id` of the ingestion. |
| `Sbom::VulnerabilitiesCreatedEvent` | `software_composition_analysis` | EE | Published when new vulnerabilities are created from SBOM findings during vulnerability scanning, carrying a batch of finding payloads. |

## Search

| Event | Feature category | Edition | Description |
|-------|-----------------|---------|-------------|
| `Search::Zoekt::ForceUpdateOverprovisionedIndexEvent` | `global_search` | EE | Published when overprovisioned, ready Zoekt indices with up-to-date used-storage stats are detected, signaling that their watermark levels should be recalculated and corrected. |
| `Search::Zoekt::IndexMarkPendingEvictionEvent` | `global_search` | EE | Published when Zoekt indices that meet the criteria to be marked as pending eviction are detected, so they can be transitioned to the pending-eviction state. |
| `Search::Zoekt::IndexMarkedAsReadyEvent` | `global_search` | EE | Published when initializing Zoekt indices have all of their repositories finished indexing and can therefore be transitioned to the ready state. |
| `Search::Zoekt::IndexMarkedAsToDeleteEvent` | `global_search` | EE | Published when Zoekt indices are eligible for deletion, so the subscribed worker can mark them as pending deletion and clean them up. |
| `Search::Zoekt::IndexToEvictEvent` | `global_search` | EE | Published when Zoekt indices in the pending-eviction state are detected, so the subscribed worker can perform the eviction and free their storage. |
| `Search::Zoekt::InitialIndexingEvent` | `global_search` | EE | Published once per pending Zoekt index assigned to an online node, so the subscribed worker can perform the initial indexing of its repositories. |
| `Search::Zoekt::LostNodeEvent` | `global_search` | EE | Published when a Zoekt node is detected as lost (no longer reporting) while at least one online node remains, so the subscribed worker can clean up the node's resources. |
| `Search::Zoekt::NodeWithNegativeUnclaimedStorageEvent` | `global_search` | EE | Published when Zoekt nodes are observed with negative unclaimed storage bytes, so the subscribed worker can take corrective action (such as moving namespaces off the over-allocated nodes). |
| `Search::Zoekt::OrphanedIndexEvent` | `global_search` | EE | Published when Zoekt indices that no longer have an associated replica or namespace are detected, so the subscribed worker can mark them as orphaned for deletion. |
| `Search::Zoekt::OrphanedRepoEvent` | `global_search` | EE | Published when Zoekt repositories with no parent project (or otherwise dangling) are detected, so the subscribed worker can mark them as orphaned for cleanup. |
| `Search::Zoekt::RepoMarkedAsToDeleteEvent` | `global_search` | EE | Published when Zoekt repositories that should be deleted are detected, so the subscribed worker can mark them for deletion and remove them from the index. |
| `Search::Zoekt::RepoToIndexEvent` | `global_search` | EE | Published when Zoekt repositories pending indexing are detected, so the subscribed worker can enqueue indexing tasks for them. |
| `Search::Zoekt::RepoToReindexEvent` | `global_search` | EE | Published when Zoekt repositories require reindexing, so the subscribed worker can enqueue reindex tasks (one event per node for parallel processing). |
| `Search::Zoekt::SaasRolloutEvent` | `global_search` | EE | Published periodically on GitLab.com to drive the SaaS rollout of Zoekt exact code search to enabled namespaces. |
| `Search::Zoekt::TaskFailedEvent` | `global_search` | EE | Published when a Zoekt indexing task exhausts its retries and is moved to the failed state, so subscribers can react to the failure. |
| `Search::Zoekt::TooManyReplicasEvent` | `global_search` | EE | Published when more Zoekt replicas exist for a namespace than the configured replica count, so the subscribed worker can prune the excess replicas. |
| `Search::Zoekt::UpdateIndexUsedStorageBytesEvent` | `global_search` | EE | Published when Zoekt indices with stale used-storage statistics are detected, so the subscribed worker can refresh their `used_storage_bytes` from the underlying repositories. |

## Security

| Event | Feature category | Edition | Description |
|-------|-----------------|---------|-------------|
| `Security::PolicyCreatedEvent` | `security_policy_management` | EE | Published when a new security policy is persisted as part of syncing a security policy project's configuration. |
| `Security::PolicyDeletedEvent` | `security_policy_management` | EE | Published when a security policy is removed during synchronization of a security policy project's configuration. |
| `Security::PolicyDismissalPreservedEvent` | `security_policy_management` | EE | Published when a Security::PolicyDismissal is preserved (transitioned to the `preserved` status) because it still applies to outstanding violations. |
| `Security::PolicyResyncEvent` | `security_policy_management` | EE | Published to force a full resynchronization of a security policy's configuration against its linked projects. |
| `Security::PolicyUpdatedEvent` | `security_policy_management` | EE | Published when a security policy's attributes or rules change during synchronization of a security policy project's configuration. Carries a diff and a rules_diff payload describing the changes. |
| `Security::ReportsIngestedEvent` | `security_policy_management` | EE | Published after a pipeline's security reports have been stored, signalling that downstream consumers (such as scan result policy evaluation) can run against the ingested findings. |

## Users

| Event | Feature category | Edition | Description |
|-------|-----------------|---------|-------------|
| `Users::ActivityEvent` | `user_management` | CE | Published to record user activity within a namespace, used for tracking seat usage and last activity timestamps. Emitted from web request after-actions (when a user and group/project context are both present), from EventCreateService push/design activity, and from Git HTTP and Gitaly-SSH operations. |

## Vulnerabilities

| Event | Feature category | Edition | Description |
|-------|-----------------|---------|-------------|
| `Vulnerabilities::BulkDismissedEvent` | `vulnerability_management` | EE | Published when a batch of vulnerabilities is dismissed via the bulk dismiss service. Carries an array of per-vulnerability attributes including dismissal reason, optional comment, and the acting user. |
| `Vulnerabilities::BulkRedetectedEvent` | `vulnerability_management` | EE | Published when previously resolved vulnerabilities are transitioned back to detected during security finding ingestion. |
| `Vulnerabilities::LinkToExternalIssueTrackerCreated` | `vulnerability_management` | EE | Published when a vulnerability is linked to an issue in an external issue tracker (for example, Jira). |
| `Vulnerabilities::LinkToExternalIssueTrackerRemoved` | `vulnerability_management` | EE | Published when a vulnerability's link to an external issue tracker is removed. |

## Work Items

| Event | Feature category | Edition | Description |
|-------|-----------------|---------|-------------|
| `WorkItems::BulkUpdatedEvent` | `team_planning` | CE | Published after a batch of work items is updated in bulk (for example, milestone cleared on milestone destroy, parent link changes). Each event batch covers up to EVENTS_BATCH_SIZE work items; published via publish_group. |
| `WorkItems::WorkItemClosedEvent` | `team_planning` | EE | Published when a work item (issue or epic work item) is closed. |
| `WorkItems::WorkItemCreatedEvent` | `team_planning` | CE | Published after a new work item (issue, task, etc.) is created. |
| `WorkItems::WorkItemDeletedEvent` | `team_planning` | CE | Published after a work item is permanently deleted. |
| `WorkItems::WorkItemReopenedEvent` | `team_planning` | EE | Published when a previously closed work item (issue or epic work item) is reopened. |
| `WorkItems::WorkItemUpdatedEvent` | `team_planning` | CE | Published after a work item's attributes are updated. |
<!-- vale on -->
