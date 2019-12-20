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

      Notes::CreateService.new(project, user, note_params).execute
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

      Notes::CreateService.new(project, user, note_params).execute
      print '.'
    end
  end
end
