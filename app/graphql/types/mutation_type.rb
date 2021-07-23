# frozen_string_literal: true

module Types
  class MutationType < BaseObject
    include Gitlab::Graphql::MountMutation

    graphql_name 'Mutation'

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
    mount_mutation Mutations::Branches::Create, calls_gitaly: true
    mount_mutation Mutations::Commits::Create, calls_gitaly: true
    mount_mutation Mutations::CustomEmoji::Create, feature_flag: :custom_emoji
    mount_mutation Mutations::Discussions::ToggleResolve
    mount_mutation Mutations::Environments::CanaryIngress::Update
    mount_mutation Mutations::Issues::Create
    mount_mutation Mutations::Issues::SetAssignees
    mount_mutation Mutations::Issues::SetConfidential
    mount_mutation Mutations::Issues::SetLocked
    mount_mutation Mutations::Issues::SetDueDate
    mount_mutation Mutations::Issues::SetSeverity
    mount_mutation Mutations::Issues::SetSubscription
    mount_mutation Mutations::Issues::Update
    mount_mutation Mutations::Issues::Move
    mount_mutation Mutations::Labels::Create
    mount_mutation Mutations::MergeRequests::Accept
    mount_mutation Mutations::MergeRequests::Create
    mount_mutation Mutations::MergeRequests::Update
    mount_mutation Mutations::MergeRequests::SetLabels
    mount_mutation Mutations::MergeRequests::SetLocked
    mount_mutation Mutations::MergeRequests::SetMilestone
    mount_mutation Mutations::MergeRequests::SetSubscription
    mount_mutation Mutations::MergeRequests::SetWip,
                   calls_gitaly: true,
                   deprecated: { reason: 'Use mergeRequestSetDraft', milestone: '13.12' }
    mount_mutation Mutations::MergeRequests::SetDraft, calls_gitaly: true
    mount_mutation Mutations::MergeRequests::SetAssignees
    mount_mutation Mutations::MergeRequests::ReviewerRereview
    mount_mutation Mutations::Metrics::Dashboard::Annotations::Create
    mount_mutation Mutations::Metrics::Dashboard::Annotations::Delete
    mount_mutation Mutations::Notes::Create::Note, calls_gitaly: true
    mount_mutation Mutations::Notes::Create::DiffNote, calls_gitaly: true
    mount_mutation Mutations::Notes::Create::ImageDiffNote, calls_gitaly: true
    mount_mutation Mutations::Notes::Update::Note
    mount_mutation Mutations::Notes::Update::ImageDiffNote
    mount_mutation Mutations::Notes::RepositionImageDiffNote
    mount_mutation Mutations::Notes::Destroy
    mount_mutation Mutations::Releases::Create
    mount_mutation Mutations::Releases::Update
    mount_mutation Mutations::Releases::Delete
    mount_mutation Mutations::ReleaseAssetLinks::Create
    mount_mutation Mutations::ReleaseAssetLinks::Update
    mount_mutation Mutations::ReleaseAssetLinks::Delete
    mount_mutation Mutations::Terraform::State::Delete
    mount_mutation Mutations::Terraform::State::Lock
    mount_mutation Mutations::Terraform::State::Unlock
    mount_mutation Mutations::Todos::Create
    mount_mutation Mutations::Todos::MarkDone
    mount_mutation Mutations::Todos::Restore
    mount_mutation Mutations::Todos::MarkAllDone
    mount_mutation Mutations::Todos::RestoreMany
    mount_mutation Mutations::Snippets::Destroy
    mount_mutation Mutations::Snippets::Update
    mount_mutation Mutations::Snippets::Create
    mount_mutation Mutations::Snippets::MarkAsSpam
    mount_mutation Mutations::JiraImport::Start
    mount_mutation Mutations::JiraImport::ImportUsers
    mount_mutation Mutations::DesignManagement::Upload, calls_gitaly: true
    mount_mutation Mutations::DesignManagement::Delete, calls_gitaly: true
    mount_mutation Mutations::DesignManagement::Move
    mount_mutation Mutations::ContainerExpirationPolicies::Update
    mount_mutation Mutations::ContainerRepositories::Destroy
    mount_mutation Mutations::ContainerRepositories::DestroyTags
    mount_mutation Mutations::Ci::Pipeline::Cancel
    mount_mutation Mutations::Ci::Pipeline::Destroy
    mount_mutation Mutations::Ci::Pipeline::Retry
    mount_mutation Mutations::Ci::CiCdSettingsUpdate
    mount_mutation Mutations::Ci::Job::Play
    mount_mutation Mutations::Ci::Job::Retry
    mount_mutation Mutations::Ci::JobTokenScope::AddProject
    mount_mutation Mutations::Ci::JobTokenScope::RemoveProject
    mount_mutation Mutations::Ci::Runner::Update, feature_flag: :runner_graphql_query
    mount_mutation Mutations::Ci::Runner::Delete, feature_flag: :runner_graphql_query
    mount_mutation Mutations::Ci::RunnersRegistrationToken::Reset, feature_flag: :runner_graphql_query
    mount_mutation Mutations::Namespace::PackageSettings::Update
    mount_mutation Mutations::UserCallouts::Create
    mount_mutation Mutations::Packages::Destroy
    mount_mutation Mutations::Packages::DestroyFile
    mount_mutation Mutations::Echo
  end
end

::Types::MutationType.prepend(::Types::DeprecatedMutations)
::Types::MutationType.prepend_mod_with('Types::MutationType')
