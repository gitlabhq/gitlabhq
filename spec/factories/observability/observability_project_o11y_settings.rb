# frozen_string_literal: true

FactoryBot.define do
  factory :observability_project_o11y_setting, class: 'Observability::ProjectO11ySetting' do
    project
    namespace factory: :group

    trait :with_creator do
      created_by factory: :user
    end
  end
end
