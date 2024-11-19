# frozen_string_literal: true

module Gitlab
  module Faker
    module Internet
      extend self

      MAX_TRIES = 10

      def unique_username
        MAX_TRIES.times do
          username = ::FFaker::Internet.unique.user_name
          return username unless User.ends_with_reserved_file_extension?(username)
        end

        raise FFaker::UniqueUtils::RetryLimitExceeded, "Retry limit exceeded for unique_username"
      end
    end
  end
end
