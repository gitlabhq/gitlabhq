# frozen_string_literal: true

module Db
  module Fixtures
    module Development
      class SpamLog
        def self.seed
          Gitlab::Seeder.quiet do
            (::SpamLog.default_per_page + 3).times do |i|
              ::SpamLog.create(
                user: self.random_user,
                user_agent: FFaker::Lorem.sentence,
                source_ip: FFaker::Internet.ip_v4_address,
                title: FFaker::Lorem.sentence,
                description: FFaker::Lorem.paragraph,
                via_api: FFaker::Boolean.random,
                submitted_as_ham: FFaker::Boolean.random,
                recaptcha_verified: FFaker::Boolean.random)
              print '.'
            end
          end
        end

        def self.random_user
          User.find(User.not_mass_generated.pluck(:id).sample)
        end
      end
    end
  end
end

Db::Fixtures::Development::SpamLog.seed
