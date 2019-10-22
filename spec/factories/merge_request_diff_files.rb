# frozen_string_literal: true

FactoryBot.define do
  factory :merge_request_diff_file do
    association :merge_request_diff

    relative_order { 0 }
    new_file { true }
    renamed_file { false }
    deleted_file { false }
    too_large { false }
    a_mode { 0 }
    b_mode { 100644 }
    new_path { 'foo' }
    old_path { 'foo' }
    diff { '' }
    binary { false }

    trait :new_file do
      relative_order { 0 }
      new_file { true }
      renamed_file { false }
      deleted_file { false }
      too_large { false }
      a_mode { 0 }
      b_mode { 100644 }
      new_path { 'foo' }
      old_path { 'foo' }
      diff { '' }
      binary { false }
    end

    trait :renamed_file do
      relative_order { 662 }
      new_file { false }
      renamed_file { true }
      deleted_file { false }
      too_large { false }
      a_mode { 100644 }
      b_mode { 100644 }
      new_path { 'bar' }
      old_path { 'baz' }
      diff { '' }
      binary { false }
    end
  end
end
