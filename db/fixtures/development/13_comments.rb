Gitlab::Seeder.quiet do
  Issue.all.each do |issue|
    project = issue.project

    project.team.users.each do |user|
      note_params = {
        noteable_type: 'Issue',
        noteable_id: issue.id,
        note: Faker::Lorem.sentence,
      }

      Notes::CreateService.new(project, user, note_params).execute
      print '.'
    end
  end

  MergeRequest.all.each do |mr|
    project = mr.project

    project.team.users.each do |user|
      note_params = {
        noteable_type: 'MergeRequest',
        noteable_id: mr.id,
        note: Faker::Lorem.sentence,
      }

      Notes::CreateService.new(project, user, note_params).execute
      print '.'
    end
  end
end
