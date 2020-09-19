# frozen_string_literal: true

FactoryBot.define do
  factory :pages_deployment, class: 'PagesDeployment' do
    project
    file_store { ObjectStorage::SUPPORTED_STORES.first }
    size { 1.megabytes }

    # TODO: replace with proper file uploaded in https://gitlab.com/gitlab-org/gitlab/-/issues/245295
    file { "dummy string" }
  end
end
