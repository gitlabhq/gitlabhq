# frozen_string_literal: true

FactoryBot.define do
  factory :lfs_file_lock do
    user
    project
    path 'README.md'
  end
end
