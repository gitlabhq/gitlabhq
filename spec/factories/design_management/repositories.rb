# frozen_string_literal: true

FactoryBot.define do
  factory :design_management_repository, class: 'DesignManagement::Repository' do
    project
  end
end
