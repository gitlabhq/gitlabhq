require './spec/support/sidekiq'

Gitlab::Seeder.quiet do
  emoji = Gitlab::Emoji.emojis.keys

  Issue.order(Gitlab::Database.random).limit(Issue.count / 2).each do |issue|
    project = issue.project

    project.team.users.sample(2).each do |user|
      issue.create_award_emoji(emoji.sample, user)

      issue.notes.sample(2).each do |note|
        next if note.system?
        note.create_award_emoji(emoji.sample, user)
      end

      print '.'
    end
  end

  MergeRequest.order(Gitlab::Database.random).limit(MergeRequest.count / 2).each do |mr|
    project = mr.project

    project.team.users.sample(2).each do |user|
      mr.create_award_emoji(emoji.sample, user)

      mr.notes.sample(2).each do |note|
        next if note.system?
        note.create_award_emoji(emoji.sample, user)
      end

      print '.'
    end
  end
end
