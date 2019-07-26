# frozen_string_literal: true

FactoryBot.define do
  factory :project_member do
    user
    project
    maintainer

    trait(:guest)     { access_level ProjectMember::GUEST }
    trait(:reporter)  { access_level ProjectMember::REPORTER }
    trait(:developer) { access_level ProjectMember::DEVELOPER }
    trait(:maintainer) { access_level ProjectMember::MAINTAINER }
    trait(:access_request) { requested_at { Time.now } }

    trait(:invited) do
      user_id nil
      invite_token 'xxx'
      invite_email 'email@email.com'
    end
  end
end
