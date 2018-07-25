FactoryBot.define do
  factory :import_export_upload do
    project { create(:project) }
  end
end
