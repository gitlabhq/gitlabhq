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

              label_title = "abuse_report_label_#{FactoryBot.generate(:label_title)}"
              ::AntiAbuse::Reports::Label.create(
                title: label_title,
                description: FFaker::Lorem.sentence,
                color: "#{::Gitlab::Color.color_for(label_title)}"
              )

              label_ids = ::AntiAbuse::Reports::Label.pluck(:id).sample(rand(5))

              ::AbuseReport.create(
                reporter: ::User.take,
                user: reported_user,
                message: 'User sends spam',
                label_ids: label_ids
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
