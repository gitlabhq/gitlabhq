FactoryGirl.define do
  factory :file_uploader, class: FileUploader do
    project
    secret nil

    transient do
      path { File.join(Rails.root, 'spec/fixtures/rails_sample.jpg') }
      file { Rack::Test::UploadedFile.new(path) }
    end

    after(:build) do |uploader, evaluator|
      uploader.store!(evaluator.file)
    end

    initialize_with do
      new(project, secret)
    end
  end
end
