# frozen_string_literal: true

FactoryBot.define do
  factory :design_action, class: 'DesignManagement::Action' do
    design
    association :version, factory: :design_version
    event { :creation }

    trait :with_image_v432x230 do
      image_v432x230 { fixture_file_upload('spec/fixtures/dk.png') }
    end
  end
end
