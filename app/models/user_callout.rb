# frozen_string_literal: true

class UserCallout < ApplicationRecord
  belongs_to :user

  # We use `UserCalloutEnums.feature_names` here so that EE can more easily
  # extend this `Hash` with new values.
  enum feature_name: ::UserCalloutEnums.feature_names

  validates :user, presence: true
  validates :feature_name,
    presence: true,
    uniqueness: { scope: :user_id },
    inclusion: { in: UserCallout.feature_names.keys }
end
