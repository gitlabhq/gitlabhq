class Gitlab::Seeder::Users
  include ActionView::Helpers::NumberHelper

  RANDOM_USERS_COUNT = 20
  MASS_USERS_COUNT = 1_500_000

  attr_reader :opts

  def initialize(opts = {})
    @opts = opts
  end

  def seed!
    Sidekiq::Testing.inline! do
      create_random_users!
      create_mass_users!
    end
  end

  private

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

  def create_mass_users!
    # Disable database insertion logs so speed isn't limited by ability to print to console
    old_logger = ActiveRecord::Base.logger
    ActiveRecord::Base.logger = nil

    encrypted_password = Devise::Encryptor.digest(User, '12345678')

    User.insert_using_generate_series(1, MASS_USERS_COUNT, debug: true) do |sql|
      sql.username = raw("'user' || seq")
      sql.name = raw("'User ' || seq")
      sql.email = raw("'user' || seq || '@example.com'")
      sql.confirmed_at = raw("('1388530801'::timestamp + seq)::date") # 2014-01-01
      sql.encrypted_password = encrypted_password
    end
    puts "\n#{number_with_delimiter(MASS_USERS_COUNT)} users created!"

    # Reset logging
    ActiveRecord::Base.logger = old_logger
  end
end

Gitlab::Seeder.quiet do
  users = Gitlab::Seeder::Users.new
  users.seed!
end
