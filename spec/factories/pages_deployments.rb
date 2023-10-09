# frozen_string_literal: true

FactoryBot.define do
  factory :pages_deployment, class: 'PagesDeployment' do
    project

    transient do
      filename { nil }
    end

    after(:build) do |deployment, evaluator|
      file = UploadedFile.new("spec/fixtures/pages.zip", filename: evaluator.filename)

      deployment.file = file
      deployment.file_sha256 = Digest::SHA256.file(file.path).hexdigest
      ::Zip::File.open(file.path) do |zip_archive|
        deployment.file_count = zip_archive.count
      end
    end
  end
end
