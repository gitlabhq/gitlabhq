Gitlab::Seeder.quiet do
  emoji = Gitlab::AwardEmoji.emojis.keys

  Issue.all.each do |issue|
    project = issue.project

    project.team.users.sample(2) do |user|
      issue.create_award_emoji(emoji.sample, user)

      note = issue.notes.sample
      note.create_award_emoji(emoji.sample, user)
      print '.'
    end
  end

  MergeRequest.all.each do |mr|
    project = mr.project

    project.team.users.sample(2).each do |user|
      mr.create_award_emoji(emoji.sample, user)

      note = mr.notes.sample
      note.create_award_emoji(emoji.sample, user)
      print '.'
    end
  end
end
