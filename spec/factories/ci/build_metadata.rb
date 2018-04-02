FactoryBot.define do
  factory :ci_build_metadata, class: Ci::BuildMetadata do
    build factory: :ci_build

    after(:build) do |build_metadata, _|
      build_metadata.project ||= build_metadata.build.project
    end
  end
end
