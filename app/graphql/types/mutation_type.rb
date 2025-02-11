# frozen_string_literal: true

module Types
  class MutationType < BaseObject
    graphql_name 'Mutation'

    include Gitlab::Graphql::MountMutation

    mount_mutation Mutations::Achievements::Award, experiment: { milestone: '15.10' }
    mount_mutation Mutations::Achievements::Create, experiment: { milestone: '15.8' }
    mount_mutation Mutations::Achievements::Delete, experiment: { milestone: '15.11' }
    mount_mutation Mutations::Achievements::DeleteUserAchievement, experiment: { milestone: '16.1' }
    mount_mutation Mutations::Achievements::Revoke, experiment: { milestone: '15.10' }
    mount_mutation Mutations::Achievements::Update, experiment: { milestone: '15.11' }
    mount_mutation Mutations::Achievements::UpdateUserAchievement, experiment: { milestone: '17.3' }
    mount_mutation Mutations::Achievements::UpdateUserAchievementPriorities, experiment: { milestone: '16.5' }
    mount_mutation Mutations::Admin::SidekiqQueues::DeleteJobs
    mount_mutation Mutations::AlertManagement::CreateAlertIssue
    mount_mutation Mutations::AlertManagement::UpdateAlertStatus
    mount_mutation Mutations::AlertManagement::Alerts::SetAssignees
    mount_mutation Mutations::AlertManagement::Alerts::Todo::Create
    mount_mutation Mutations::AlertManagement::HttpIntegration::Create
    mount_mutation Mutations::AlertManagement::HttpIntegration::Update
    mount_mutation Mutations::AlertManagement::HttpIntegration::ResetToken
    mount_mutation Mutations::AlertManagement::HttpIntegration::Destroy
    mount_mutation Mutations::Security::CiConfiguration::ConfigureSast
    mount_mutation Mutations::Security::CiConfiguration::ConfigureSastIac
    mount_mutation Mutations::Security::CiConfiguration::ConfigureSecretDetection
    mount_mutation Mutations::AlertManagement::PrometheusIntegration::Create
    mount_mutation Mutations::AlertManagement::PrometheusIntegration::Update
    mount_mutation Mutations::AlertManagement::PrometheusIntegration::ResetToken
    mount_mutation Mutations::AwardEmojis::Add
    mount_mutation Mutations::AwardEmojis::Remove
    mount_mutation Mutations::AwardEmojis::Toggle
    mount_mutation Mutations::Boards::Create
    mount_mutation Mutations::Boards::Destroy
    mount_mutation Mutations::Boards::Update
    mount_mutation Mutations::Boards::Issues::IssueMoveList
    mount_mutation Mutations::Boards::Lists::Create
    mount_mutation Mutations::Boards::Lists::Update
    mount_mutation Mutations::Boards::Lists::Destroy
    mount_mutation Mutations::Repositories::Branches::Create, calls_gitaly: true
    mount_mutation Mutations::Repositories::Branches::Delete, calls_gitaly: true
    mount_mutation Mutations::Repositories::Tags::Create, calls_gitaly: true
    mount_mutation Mutations::Repositories::Tags::Delete, calls_gitaly: true
    mount_mutation Mutations::Clusters::Agents::Create
    mount_mutation Mutations::Clusters::Agents::Delete
    mount_mutation Mutations::Clusters::AgentTokens::Create
    mount_mutation Mutations::Clusters::AgentTokens::Revoke
    mount_mutation Mutations::Commits::Create, calls_gitaly: true
    mount_mutation Mutations::CustomEmoji::Create
    mount_mutation Mutations::CustomEmoji::Destroy
    mount_mutation Mutations::CustomerRelations::Contacts::Create
    mount_mutation Mutations::CustomerRelations::Contacts::Update
    mount_mutation Mutations::CustomerRelations::Organizations::Create
    mount_mutation Mutations::CustomerRelations::Organizations::Update
    mount_mutation Mutations::Discussions::ToggleResolve
    mount_mutation Mutations::DependencyProxy::ImageTtlGroupPolicy::Update
    mount_mutation Mutations::DependencyProxy::GroupSettings::Update
    mount_mutation Mutations::Environments::CanaryIngress::Update
    mount_mutation Mutations::Environments::Create
    mount_mutation Mutations::Environments::Delete
    mount_mutation Mutations::Environments::Stop
    mount_mutation Mutations::Environments::Update
    mount_mutation Mutations::Import::SourceUsers::CancelReassignment, experiment: { milestone: '17.2' }
    mount_mutation Mutations::Import::SourceUsers::KeepAllAsPlaceholder, experiment: { milestone: '17.6' }
    mount_mutation Mutations::Import::SourceUsers::KeepAsPlaceholder, experiment: { milestone: '17.2' }
    mount_mutation Mutations::Import::SourceUsers::Reassign, experiment: { milestone: '17.2' }
    mount_mutation Mutations::Import::SourceUsers::ResendNotification, experiment: { milestone: '17.2' }
    mount_mutation Mutations::IncidentManagement::TimelineEvent::Create, experiment: { milestone: '15.6' }
    mount_mutation Mutations::IncidentManagement::TimelineEvent::PromoteFromNote
    mount_mutation Mutations::IncidentManagement::TimelineEvent::Update
    mount_mutation Mutations::IncidentManagement::TimelineEvent::Destroy
    mount_mutation Mutations::IncidentManagement::TimelineEventTag::Create
    mount_mutation Mutations::Integrations::Exclusions::Create, experiment: { milestone: '17.0' }
    mount_mutation Mutations::Integrations::Exclusions::Delete, experiment: { milestone: '17.0' }
    mount_mutation Mutations::Issues::Create
    mount_mutation Mutations::Issues::SetAssignees
    mount_mutation Mutations::Issues::SetCrmContacts
    mount_mutation Mutations::Issues::SetConfidential
    mount_mutation Mutations::Issues::SetLocked
    mount_mutation Mutations::Issues::SetDueDate
    mount_mutation Mutations::Issues::SetSeverity
    mount_mutation Mutations::Issues::SetSubscription
    mount_mutation Mutations::Issues::SetEscalationStatus
    mount_mutation Mutations::Issues::Update
    mount_mutation Mutations::Issues::Move
    mount_mutation Mutations::Issues::LinkAlerts
    mount_mutation Mutations::Issues::UnlinkAlert
    mount_mutation Mutations::Issues::BulkUpdate, experiment: { milestone: '15.9' }
    mount_mutation Mutations::Labels::Create
    mount_mutation Mutations::Members::Groups::BulkUpdate
    mount_mutation Mutations::Members::Projects::BulkUpdate
    mount_mutation Mutations::MergeRequests::Accept
    mount_mutation Mutations::MergeRequests::Create
    mount_mutation Mutations::MergeRequests::Update
    mount_mutation Mutations::MergeRequests::SetLabels
    mount_mutation Mutations::MergeRequests::SetLocked
    mount_mutation Mutations::MergeRequests::SetMilestone
    mount_mutation Mutations::MergeRequests::SetSubscription
    mount_mutation Mutations::MergeRequests::SetDraft, calls_gitaly: true
    mount_mutation Mutations::MergeRequests::SetAssignees
    mount_mutation Mutations::MergeRequests::SetReviewers
    mount_mutation Mutations::MergeRequests::ReviewerRereview
    mount_mutation Mutations::Metrics::Dashboard::Annotations::Create, deprecated: {
      reason: 'Underlying feature was removed in 16.0',
      milestone: '16.0'
    }
    mount_mutation Mutations::Metrics::Dashboard::Annotations::Delete, deprecated: {
      reason: 'Underlying feature was removed in 16.0',
      milestone: '16.0'
    }
    mount_mutation Mutations::Notes::AbuseReport::Create
    mount_mutation Mutations::Notes::AbuseReport::Update, experiment: { milestone: '17.5' }
    mount_mutation Mutations::Notes::Create::Note, calls_gitaly: true
    mount_mutation Mutations::Notes::Create::DiffNote, calls_gitaly: true
    mount_mutation Mutations::Notes::Create::ImageDiffNote, calls_gitaly: true
    mount_mutation Mutations::Notes::Create::Discussion, calls_gitaly: true
    mount_mutation Mutations::Notes::Update::Note
    mount_mutation Mutations::Notes::Update::ImageDiffNote
    mount_mutation Mutations::Notes::ConvertToThread
    mount_mutation Mutations::Notes::RepositionImageDiffNote
    mount_mutation Mutations::Notes::Destroy
    mount_mutation Mutations::Organizations::Create, experiment: { milestone: '16.6' }
    mount_mutation Mutations::Organizations::Update, experiment: { milestone: '16.7' }
    mount_mutation Mutations::Organizations::OrganizationUsers::Update, experiment: { milestone: '17.5' }
    mount_mutation Mutations::Projects::BlobsRemove, calls_gitaly: true, experiment: { milestone: '17.1' }
    mount_mutation Mutations::Projects::SyncFork, calls_gitaly: true, experiment: { milestone: '15.9' }
    mount_mutation Mutations::Projects::TextReplace, calls_gitaly: true, experiment: { milestone: '17.1' }
    mount_mutation Mutations::Projects::Star, experiment: { milestone: '16.7' }
    mount_mutation Mutations::BranchRules::Update, experiment: { milestone: '16.7' }
    mount_mutation Mutations::BranchRules::Create, experiment: { milestone: '16.7' }
    mount_mutation Mutations::Releases::Create
    mount_mutation Mutations::Releases::Update
    mount_mutation Mutations::Releases::Delete
    mount_mutation Mutations::ReleaseAssetLinks::Create
    mount_mutation Mutations::ReleaseAssetLinks::Update
    mount_mutation Mutations::ReleaseAssetLinks::Delete
    mount_mutation Mutations::Terraform::State::Delete
    mount_mutation Mutations::Terraform::State::Lock
    mount_mutation Mutations::Terraform::State::Unlock
    mount_mutation Mutations::Timelogs::Create
    mount_mutation Mutations::Timelogs::Delete
    mount_mutation Mutations::Todos::Create
    mount_mutation Mutations::Todos::MarkDone
    mount_mutation Mutations::Todos::Restore
    mount_mutation Mutations::Todos::MarkAllDone
    mount_mutation Mutations::Todos::ResolveMany, experiment: { milestone: '17.9' }
    mount_mutation Mutations::Todos::RestoreMany
    mount_mutation Mutations::Todos::Snooze, experiment: { milestone: '17.4' }
    mount_mutation Mutations::Todos::UnSnooze, experiment: { milestone: '17.4' }
    mount_mutation Mutations::Todos::SnoozeMany, experiment: { milestone: '17.9' }
    mount_mutation Mutations::Todos::UnsnoozeMany, experiment: { milestone: '17.9' }
    mount_mutation Mutations::Snippets::Destroy
    mount_mutation Mutations::Snippets::Update
    mount_mutation Mutations::Snippets::Create
    mount_mutation Mutations::Snippets::MarkAsSpam
    mount_mutation Mutations::JiraImport::Start
    mount_mutation Mutations::JiraImport::ImportUsers
    mount_mutation Mutations::DesignManagement::Upload, calls_gitaly: true
    mount_mutation Mutations::DesignManagement::Delete, calls_gitaly: true
    mount_mutation Mutations::DesignManagement::Move
    mount_mutation Mutations::DesignManagement::Update
    mount_mutation Mutations::ContainerExpirationPolicies::Update
    mount_mutation Mutations::ContainerRegistry::Protection::Rule::Create
    mount_mutation Mutations::ContainerRegistry::Protection::Rule::Delete
    mount_mutation Mutations::ContainerRegistry::Protection::Rule::Update
    mount_mutation Mutations::ContainerRegistry::Protection::TagRule::Create, experiment: { milestone: '17.8' }
    mount_mutation Mutations::ContainerRegistry::Protection::TagRule::Delete, experiment: { milestone: '17.8' }
    mount_mutation Mutations::ContainerRegistry::Protection::TagRule::Update, experiment: { milestone: '17.8' }
    mount_mutation Mutations::ContainerRepositories::Destroy
    mount_mutation Mutations::ContainerRepositories::DestroyTags
    mount_mutation Mutations::Ci::Catalog::Resources::Create, experiment: { milestone: '15.11' }
    mount_mutation Mutations::Ci::Catalog::Resources::Destroy, experiment: { milestone: '16.6' }
    mount_mutation Mutations::Ci::Job::Cancel
    mount_mutation Mutations::Ci::Job::Play
    mount_mutation Mutations::Ci::Job::Retry
    mount_mutation Mutations::Ci::Job::ArtifactsDestroy
    mount_mutation Mutations::Ci::Job::Unschedule
    mount_mutation Mutations::Ci::JobTokenScope::AddGroupOrProject
    mount_mutation Mutations::Ci::JobTokenScope::AddProject
    mount_mutation Mutations::Ci::JobArtifact::BulkDestroy, experiment: { milestone: '15.10' }
    mount_mutation Mutations::Ci::JobArtifact::Destroy
    mount_mutation Mutations::Ci::JobTokenScope::RemoveGroup
    mount_mutation Mutations::Ci::JobTokenScope::RemoveProject
    mount_mutation Mutations::Ci::JobTokenScope::UpdateJobTokenPolicies, experiment: { milestone: '17.6' }
    mount_mutation Mutations::Ci::JobTokenScope::AutopopulateAllowlist, experiment: { milestone: '17.9' }
    mount_mutation Mutations::Ci::JobTokenScope::ClearAllowlistAutopopulations, experiment: { milestone: '17.9' }
    mount_mutation Mutations::Ci::NamespaceSettingsUpdate, experiment: { milestone: '17.9' }
    mount_mutation Mutations::Ci::Pipeline::Cancel
    mount_mutation Mutations::Ci::Pipeline::Create
    mount_mutation Mutations::Ci::Pipeline::Destroy
    mount_mutation Mutations::Ci::Pipeline::Retry
    mount_mutation Mutations::Ci::PipelineSchedule::Create
    mount_mutation Mutations::Ci::PipelineSchedule::Delete
    mount_mutation Mutations::Ci::PipelineSchedule::Play
    mount_mutation Mutations::Ci::PipelineSchedule::TakeOwnership
    mount_mutation Mutations::Ci::PipelineSchedule::Update
    mount_mutation Mutations::Ci::PipelineTrigger::Create, experiment: { milestone: '16.3' }
    mount_mutation Mutations::Ci::PipelineTrigger::Delete, experiment: { milestone: '16.3' }
    mount_mutation Mutations::Ci::PipelineTrigger::Update, experiment: { milestone: '16.3' }
    mount_mutation Mutations::Ci::ProjectCiCdSettingsUpdate
    mount_mutation Mutations::Ci::Runner::BulkDelete, experiment: { milestone: '15.3' }
    mount_mutation Mutations::Ci::Runner::Cache::Clear
    mount_mutation Mutations::Ci::Runner::Create, experiment: { milestone: '15.10' }
    mount_mutation Mutations::Ci::Runner::Delete
    mount_mutation Mutations::Ci::Runner::Update
    mount_mutation Mutations::Ci::RunnersRegistrationToken::Reset, deprecated: {
      reason: 'Underlying feature was deprecated in 15.6 and will be removed in 18.0',
      milestone: '17.7'
    }
    mount_mutation Mutations::Namespace::PackageSettings::Update
    mount_mutation Mutations::Groups::Update
    mount_mutation Mutations::UserCallouts::Create
    mount_mutation Mutations::UserPreferences::Update
    mount_mutation Mutations::Packages::Destroy
    mount_mutation Mutations::Packages::BulkDestroy,
      extensions: [::Gitlab::Graphql::Limit::FieldCallCount => { limit: 1 }]
    mount_mutation Mutations::Packages::DestroyFile
    mount_mutation Mutations::Packages::Protection::Rule::Create
    mount_mutation Mutations::Packages::Protection::Rule::Delete
    mount_mutation Mutations::Packages::Protection::Rule::Update
    mount_mutation Mutations::Packages::DestroyFiles
    mount_mutation Mutations::Packages::Cleanup::Policy::Update
    mount_mutation Mutations::Echo
    mount_mutation Mutations::WorkItems::Create, experiment: { milestone: '15.1' }
    mount_mutation Mutations::WorkItems::CreateFromTask, experiment: { milestone: '15.1' }
    mount_mutation Mutations::WorkItems::Delete, experiment: { milestone: '15.1' }
    mount_mutation Mutations::WorkItems::Update, experiment: { milestone: '15.1' }
    mount_mutation Mutations::WorkItems::Export, experiment: { milestone: '15.10' }
    mount_mutation Mutations::WorkItems::Convert, experiment: { milestone: '15.11' }
    mount_mutation Mutations::WorkItems::LinkedItems::Add, experiment: { milestone: '16.3' }
    mount_mutation Mutations::WorkItems::LinkedItems::Remove, experiment: { milestone: '16.3' }
    mount_mutation Mutations::WorkItems::AddClosingMergeRequest, experiment: { milestone: '17.1' }
    mount_mutation Mutations::WorkItems::Hierarchy::Reorder, experiment: { milestone: '17.3' }
    mount_mutation Mutations::WorkItems::BulkUpdate, experiment: { milestone: '17.4' }
    mount_mutation Mutations::Users::SavedReplies::Create
    mount_mutation Mutations::Users::SavedReplies::Update
    mount_mutation Mutations::Users::SavedReplies::Destroy
    mount_mutation Mutations::Pages::MarkOnboardingComplete
    mount_mutation Mutations::Uploads::Delete
    mount_mutation Mutations::Users::SetNamespaceCommitEmail
    mount_mutation Mutations::WorkItems::Subscribe, experiment: { milestone: '16.3' }
    mount_mutation Mutations::Admin::AbuseReportLabels::Create, experiment: { milestone: '16.4' }
    mount_mutation Mutations::Ml::Models::Create, experiment: { milestone: '16.8' }
    mount_mutation Mutations::Ml::Models::Edit, experiment: { milestone: '17.3' }
    mount_mutation Mutations::Ml::Models::Destroy, experiment: { milestone: '16.10' }
    mount_mutation Mutations::Ml::Models::Delete, experiment: { milestone: '17.0' }
    mount_mutation Mutations::Ml::ModelVersions::Create, experiment: { milestone: '17.1' }
    mount_mutation Mutations::Ml::ModelVersions::Edit, experiment: { milestone: '17.4' }
    mount_mutation Mutations::Ml::ModelVersions::Delete, experiment: { milestone: '17.0' }
    mount_mutation Mutations::BranchRules::Delete, experiment: { milestone: '16.9' }
    mount_mutation Mutations::Pages::Deployment::Delete, experiment: { milestone: '17.1' }
    mount_mutation Mutations::Pages::Deployment::Restore, experiment: { milestone: '17.1' }
  end
end

::Types::MutationType.prepend(::Types::DeprecatedMutations)
::Types::MutationType.prepend_mod_with('Types::MutationType')
