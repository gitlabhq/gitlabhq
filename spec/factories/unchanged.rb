# frozen_string_literal: true

FactoryBot.define do
  # The unchanged trait should be used with models that rely on
  # ActiveModel::Dirty or the ReportableChanges concern to track attributes
  # changes (e.g. in constructing hook data). Calling
  # clear_changes_information ensures the change state represents that of a
  # record that was loaded from persistence and not newly created.
  trait :unchanged do
    after(:create, &:clear_changes_information)
  end
end
