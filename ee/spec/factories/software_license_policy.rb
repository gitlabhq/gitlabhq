# frozen_string_literal: true

FactoryBot.define do
  factory :software_license_policy, class: SoftwareLicensePolicy do
    approval_status 1
    project
    software_license
  end
end
