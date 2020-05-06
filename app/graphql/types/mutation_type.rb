# frozen_string_literal: true

module Types
  class MutationType < BaseObject
    include Gitlab::Graphql::MountMutation

    graphql_name 'Mutation'

    mount_mutation Mutations::Admin::SidekiqQueues::DeleteJobs
    mount_mutation Mutations::AlertManagement::UpdateAlertStatus
    mount_mutation Mutations::AwardEmojis::Add
    mount_mutation Mutations::AwardEmojis::Remove
    mount_mutation Mutations::AwardEmojis::Toggle
    mount_mutation Mutations::Branches::Create, calls_gitaly: true
    mount_mutation Mutations::Issues::SetConfidential
    mount_mutation Mutations::Issues::SetDueDate
    mount_mutation Mutations::Issues::Update
    mount_mutation Mutations::MergeRequests::SetLabels
    mount_mutation Mutations::MergeRequests::SetLocked
    mount_mutation Mutations::MergeRequests::SetMilestone
    mount_mutation Mutations::MergeRequests::SetSubscription
    mount_mutation Mutations::MergeRequests::SetWip, calls_gitaly: true
    mount_mutation Mutations::MergeRequests::SetAssignees
    mount_mutation Mutations::Notes::Create::Note, calls_gitaly: true
    mount_mutation Mutations::Notes::Create::DiffNote, calls_gitaly: true
    mount_mutation Mutations::Notes::Create::ImageDiffNote, calls_gitaly: true
    mount_mutation Mutations::Notes::Update::Note,
                   description: 'Updates a Note. If the body of the Note contains only quick actions, ' \
                                'the Note will be destroyed during the update, and no Note will be ' \
                                'returned'
    mount_mutation Mutations::Notes::Update::ImageDiffNote,
                   description: 'Updates a DiffNote on an image (a `Note` where the `position.positionType` is `"image"`). ' \
                                'If the body of the Note contains only quick actions, the Note will be ' \
                                'destroyed during the update, and no Note will be returned'
    mount_mutation Mutations::Notes::Destroy
    mount_mutation Mutations::Todos::MarkDone
    mount_mutation Mutations::Todos::Restore
    mount_mutation Mutations::Todos::MarkAllDone
    mount_mutation Mutations::Todos::RestoreMany
    mount_mutation Mutations::Snippets::Destroy
    mount_mutation Mutations::Snippets::Update
    mount_mutation Mutations::Snippets::Create
    mount_mutation Mutations::Snippets::MarkAsSpam
    mount_mutation Mutations::JiraImport::Start
  end
end

::Types::MutationType.prepend_if_ee('::EE::Types::MutationType')
