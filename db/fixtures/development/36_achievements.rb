# frozen_string_literal: true

class Gitlab::Seeder::Achievements
  attr_reader :group, :user_ids, :maintainer_ids

  def initialize(group, user_ids)
    @group = group
    @maintainer_ids = group.members.maintainers.pluck_user_ids
    @maintainer_ids << User.admins.first.id
    @user_ids = user_ids
  end

  def seed!
    achievement_ids = Achievements::Achievement.pluck(:id)
    achievement_ids = seed_achievements if achievement_ids.empty?

    user_ids.reverse.each_with_index do |user_id, user_index|
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

  def seed_achievements
    achievement_ids = []


    ['revoked', 'first mr', 'hero', 'legend'].each do |achievement_name|
      achievement_ids << ::Achievements::Achievement.create!(
        namespace_id: group.id,
        name: achievement_name,
        description: achievement_name == 'hero' ? 'Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry''s standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.' : nil,
        avatar: seed_avatar(achievement_name)
      ).id

      print '.'
    end

    achievement_ids
  end

  def seed_avatar(achievement_name)
    case achievement_name
    when 'first mr'
      File.new(Rails.root.join('db', 'fixtures', 'development', 'rocket.jpg'), 'r')
    when 'hero'
      File.new(Rails.root.join('db', 'fixtures', 'development', 'heart.png'), 'r')
    end
  end
end

Gitlab::Seeder.quiet do
  puts "\nGenerating achievements"

  group = Group.first
  users = User.first(4).pluck(:id)
  Gitlab::Seeder::Achievements.new(group, users).seed!
rescue => e
  warn "\nError seeding achievements: #{e}"
end
