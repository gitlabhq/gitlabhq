require_relative '../support/helpers/key_generator_helper'

FactoryGirl.define do
  factory :key do
    title
    key { Spec::Support::Helpers::KeyGeneratorHelper.new(1024).generate + ' dummy@gitlab.com' }

    factory :deploy_key, class: 'DeployKey'

    factory :personal_key do
      user
    end

    factory :another_key do
      factory :another_deploy_key, class: 'DeployKey'
    end

    factory :write_access_key, class: 'DeployKey' do
      can_push true
    end
  end
end
