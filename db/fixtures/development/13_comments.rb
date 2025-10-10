require './spec/support/sidekiq_middleware'

Gitlab::Seeder.quiet do
  Issue.find_each do |issue|
    project = issue.project

    project.team.users.each do |user|
      note_params = {
        noteable_type: 'Issue',
        noteable_id: issue.id,
        note: FFaker::Lorem.sentence,
      }

      Gitlab::ExclusiveLease.skipping_transaction_check do
        Notes::CreateService.new(project, user, note_params).execute
      end
      print '.'
    end
  end

  MergeRequest.find_each do |mr|
    project = mr.project

    project.team.users.each do |user|
      note_params = {
        noteable_type: 'MergeRequest',
        noteable_id: mr.id,
        note: FFaker::Lorem.sentence,
      }
      Gitlab::ExclusiveLease.skipping_transaction_check do
        Notes::CreateService.new(project, user, note_params).execute
      end
      print '.'
    end
  end
end
