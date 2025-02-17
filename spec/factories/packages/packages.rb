# frozen_string_literal: true

FactoryBot.define do
  factory :package, class: 'Packages::Package' do
    project
    creator { project&.creator }
    status { :default }

    trait :hidden do
      status { :hidden }
    end

    trait :processing do
      status { :processing }
    end

    trait :error do
      status { :error }
    end

    trait :pending_destruction do
      status { :pending_destruction }
    end

    trait :last_downloaded_at do
      last_downloaded_at { 2.days.ago }
    end

    factory :ml_model_package, class: 'Packages::MlModel::Package' do
      sequence(:name) { |n| "mlmodel-package-#{n}" }
      sequence(:version) { |n| "1.0.#{n}" }
      package_type { :ml_model }
    end
  end
end
