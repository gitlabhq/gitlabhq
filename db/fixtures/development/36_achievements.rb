# frozen_string_literal: true

class Gitlab::Seeder::Achievements
  attr_reader :group, :user_ids, :maintainer_ids

  def initialize(group, user_ids)
    @group = group
    @maintainer_ids = group.members.maintainers.pluck(:user_id)
    @user_ids = user_ids
  end

  def seed!
    achievement_ids = []

    ['revoked', 'first mr', 'hero', 'legend'].each do |achievement_name|
      achievement_ids << ::Achievements::Achievement.create!(
        namespace_id: group.id,
        name: achievement_name
      ).id

      print '.'
    end

    user_ids.each_with_index do |user_id, user_index|
      (user_index + 1).times do |achievement_index|
        ::Achievements::UserAchievement.create!(
          user_id: user_id,
          achievement_id: achievement_ids[achievement_index],
          awarded_by_user_id: maintainer_ids.sample,
          revoked_by_user_id: achievement_index == 0 ? maintainer_ids.sample : nil,
          revoked_at: achievement_index == 0 ? DateTime.current : nil
        )

        print '.'
      end
    end
  end
end

Gitlab::Seeder.quiet do
  puts "\nGenerating ahievements"

  group = Group.first
  users = User.last(4).pluck(:id)
  Gitlab::Seeder::Achievements.new(group, users).seed!
rescue => e
  warn "\nError seeding achievements: #{e}"
end
