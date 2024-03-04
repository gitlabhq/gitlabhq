# frozen_string_literal: true

FactoryBot.define do
  factory :golang_package, class: 'Packages::Go::Package' do
    project
    creator { project&.creator }
    status { :default }
    sequence(:name) { |n| "golang.org/x/pkg-#{n}" }
    sequence(:version) { |n| "v1.0.#{n}" }
    package_type { :golang }
  end
end
