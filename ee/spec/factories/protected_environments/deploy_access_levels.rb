# frozen_string_literal: true
FactoryBot.define do
  factory :protected_environment_deploy_access_level, class: ProtectedEnvironment::DeployAccessLevel do
    user nil
    group nil
    protected_environment
    access_level { Gitlab::Access::DEVELOPER }

    trait :maintainer_access do
      access_level { Gitlab::Access::MAINTAINER }
    end
  end
end
