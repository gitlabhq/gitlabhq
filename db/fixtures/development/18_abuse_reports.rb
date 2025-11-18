module Db
  module Fixtures
    module Development
      class AbuseReport
        def self.seed
          Gitlab::Seeder.quiet do
            organization = User.admins.first.organizations.first

            (::AbuseReport.default_per_page + 3).times do |i|
              username = "#{::Gitlab::Seeder::REPORTED_USER_START}#{::Gitlab::Faker::Internet.unique_username}"
              reported_user =
                ::User.create!(
                  username: username,
                  name: FFaker::Name.name,
                  email: FFaker::Internet.email,
                  confirmed_at: DateTime.now,
                  password: ::User.random_password
                ) do |user|
                  user.assign_personal_namespace(organization)
                end

              ::AbuseReport.create(
                reporter: ::User.take,
                user: reported_user,
                message: 'User sends spam',
              )

              print '.'
            end
          end
        end
      end
    end
  end
end

Db::Fixtures::Development::AbuseReport.seed
