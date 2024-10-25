module Db
  module Fixtures
    module Development
      class AbuseReport
        def self.seed
          Gitlab::Seeder.quiet do
            (::AbuseReport.default_per_page + 3).times do |i|
              reported_user =
                ::User.create!(
                  username: "reported_user_#{i}",
                  name: FFaker::Name.name,
                  email: FFaker::Internet.email,
                  confirmed_at: DateTime.now,
                  password: ::User.random_password
                ) do |user|
                  user.assign_personal_namespace(Organizations::Organization.default_organization)
                end

              label_title = "abuse_report_label_#{i}"
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
