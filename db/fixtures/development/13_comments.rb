Gitlab::Seeder.quiet do
  Issue.all.limit(10).each_with_index do |issue, i|
    5.times do
      user = issue.project.team.users.sample

      Gitlab::Seeder.by_user(user) do
        Note.seed(:id, [{
          project_id: issue.project.id,
          author_id: user.id,
          note: Faker::Lorem.sentence,
          noteable_id: issue.id,
          noteable_type: 'Issue'
        }])

        print '.'
      end
    end
  end
end
