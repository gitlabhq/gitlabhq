# frozen_string_literal: true

FactoryBot.define do
  factory :file_uploader do
    skip_create

    secret { nil }

    transient do
      fixture { 'rails_sample.jpg' }
      path { File.join(Rails.root, 'spec/fixtures', fixture) }
      file { Rack::Test::UploadedFile.new(path) }
    end

    after(:build) do |uploader, evaluator|
      uploader.store!(evaluator.file) if evaluator.model&.persisted?
    end

    initialize_with do
      klass = container.is_a?(Group) ? NamespaceFileUploader : FileUploader
      klass.new(container, nil, secret: secret)
    end
  end
end
