# frozen_string_literal: true

FactoryBot.define do
  factory :lfs_objects_project do
    lfs_object
    project
    repository_type :project
  end
end
