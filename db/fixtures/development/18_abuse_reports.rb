module Db
  module Fixtures
    module Development
      class AbuseReport
        def self.seed
          Gitlab::Seeder.quiet do
            (::AbuseReport.default_per_page + 3).times do
              reported_user =
                ::User.create!(
                  username: "#{FFaker::Internet.user_name}-reported",
                  name: FFaker::Name.name,
                  email: FFaker::Internet.email,
                  confirmed_at: DateTime.now,
                  password: '12345678'
                )

              ::AbuseReport.create(reporter: ::User.take, user: reported_user, message: 'User sends spam')
              print '.'
            end
          end
        end
      end
    end
  end
end

Db::Fixtures::Development::AbuseReport.seed
