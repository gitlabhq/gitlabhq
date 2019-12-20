# frozen_string_literal: true

class Gitlab::Seeder::Users
  include ActionView::Helpers::NumberHelper

  RANDOM_USERS_COUNT = 20
  MASS_USERS_COUNT = ENV['CI'] ? 10 : 1_000_000

  attr_reader :opts

  def initialize(opts = {})
    @opts = opts
  end

  def seed!
    Sidekiq::Testing.inline! do
      create_mass_users!
      create_random_users!
    end
  end

  private

  def create_mass_users!
    encrypted_password = Devise::Encryptor.digest(User, '12345678')

    Gitlab::Seeder.with_mass_insert(MASS_USERS_COUNT, User) do
      ActiveRecord::Base.connection.execute <<~SQL
        INSERT INTO users (username, name, email, confirmed_at, projects_limit, encrypted_password)
        SELECT
          '#{Gitlab::Seeder::MASS_INSERT_USER_START}' || seq,
          'Seed user ' || seq,
          'seed_user' || seq || '@example.com',
          to_timestamp(seq),
          #{MASS_USERS_COUNT},
          '#{encrypted_password}'
        FROM generate_series(1, #{MASS_USERS_COUNT}) AS seq
      SQL
    end

    relation = User.where(admin: false)
    Gitlab::Seeder.with_mass_insert(relation.count, Namespace) do
      ActiveRecord::Base.connection.execute <<~SQL
        INSERT INTO namespaces (name, path, owner_id)
        SELECT
          username,
          username,
          id
        FROM users WHERE NOT admin
      SQL
    end
  end

  def create_random_users!
    RANDOM_USERS_COUNT.times do |i|
      begin
        User.create!(
          username: FFaker::Internet.user_name,
          name: FFaker::Name.name,
          email: FFaker::Internet.email,
          confirmed_at: DateTime.now,
          password: '12345678'
        )

        print '.'
      rescue ActiveRecord::RecordInvalid
        print 'F'
      end
    end
  end
end

Gitlab::Seeder.quiet do
  users = Gitlab::Seeder::Users.new
  users.seed!
end
