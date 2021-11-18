require './spec/support/sidekiq_middleware'

Gitlab::Seeder.quiet do
  def seed_award_emoji(klass)
    klass.order(Gitlab::Database.random).limit(klass.count / 2).each do |awardable|
      awardable.project.authorized_users.where('project_authorizations.access_level > ?', Gitlab::Access::GUEST).sample(2).each do |user|
        AwardEmojis::AddService.new(awardable, TanukiEmoji.index.all.sample.name, user).execute

        awardable.notes.user.sample(2).each do |note|
          AwardEmojis::AddService.new(note, TanukiEmoji.index.all.sample.name, user).execute
        end

        print '.'
      end
    end
  end

  seed_award_emoji(Issue)
  seed_award_emoji(MergeRequest)
end
