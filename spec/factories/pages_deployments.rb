# frozen_string_literal: true

FactoryBot.define do
  factory :pages_deployment, class: 'PagesDeployment' do
    project

    after(:build) do |deployment, _evaluator|
      filepath = Rails.root.join("spec/fixtures/pages.zip")

      deployment.file = fixture_file_upload(filepath)
      deployment.file_sha256 = Digest::SHA256.file(filepath).hexdigest
      ::Zip::File.open(filepath) do |zip_archive|
        deployment.file_count = zip_archive.count
      end
    end
  end
end
