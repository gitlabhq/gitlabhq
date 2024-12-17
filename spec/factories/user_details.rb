# frozen_string_literal: true

FactoryBot.define do
  factory :user_detail do
    job_title { 'VP of Sales' }
    pronouns { nil }
    pronunciation { nil }

    # We are skipping create here to signal that it isn't really valid
    # to create a user_detail this way in our system.
    # User detail is created only with an associated user being created first.
    # We have now ensured that each user creation comes with a built
    # user_detail record.
    # By adding the below we more effectively put guard rails around this, by essentially
    # making `create` an alias for `build`, which is still valid to do for simple
    # model level unit tests.
    skip_create
  end
end
