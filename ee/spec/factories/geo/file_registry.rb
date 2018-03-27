FactoryBot.define do
  factory :geo_file_registry, class: Geo::FileRegistry do
    sequence(:file_id)
    file_type :file
    success true

    trait(:attachment) { file_type :attachment }
    trait(:avatar) { file_type :avatar }
    trait(:file) { file_type :file }
    trait(:job_artifact) { file_type :job_artifact }
    trait(:lfs) { file_type :lfs }
    trait(:namespace_file) { file_type :namespace_file }
    trait(:personal_file) { file_type :personal_file }

    trait :with_file do
      after(:build, :stub) do |registry, _|
        file =
          if registry.file_type.to_sym == :lfs
            create(:lfs_object)
          elsif registry.file_type.to_sym == :job_artifact
            create(:ci_job_artifact)
          else
            create(:upload)
          end

        registry.file_id = file.id
      end
    end
  end
end
