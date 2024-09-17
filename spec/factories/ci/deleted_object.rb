# frozen_string_literal: true

FactoryBot.define do
  factory :ci_deleted_object, class: 'Ci::DeletedObject' do
    pick_up_at { Time.current }
    store_dir { SecureRandom.uuid }
    file { fixture_file_upload(Rails.root.join('spec/fixtures/ci_build_artifacts.zip'), 'application/zip') }
    project_id { FactoryBot.create(:project).id }
  end
end
