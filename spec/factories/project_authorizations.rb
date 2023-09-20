# frozen_string_literal: true

FactoryBot.define do
  factory :project_authorization do
    user
    project
    access_level { Gitlab::Access::REPORTER }
  end

  trait(:guest) { access_level { Gitlab::Access::GUEST } }
  trait(:reporter) { access_level { Gitlab::Access::REPORTER } }
  trait(:developer) { access_level { Gitlab::Access::DEVELOPER } }
  trait(:maintainer) { access_level { Gitlab::Access::MAINTAINER } }
  trait(:owner) { access_level { Gitlab::Access::OWNER } }
end
