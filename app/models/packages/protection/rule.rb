# frozen_string_literal: true

module Packages
  module Protection
    class Rule < ApplicationRecord
      enum package_type: Packages::Package.package_types.slice(:npm)

      belongs_to :project, inverse_of: :package_protection_rules

      validates :package_name_pattern, presence: true, uniqueness: { scope: [:project_id, :package_type] },
        length: { maximum: 255 }
      validates :package_type, presence: true
      validates :push_protected_up_to_access_level, presence: true,
        inclusion: { in: [
          Gitlab::Access::DEVELOPER,
          Gitlab::Access::MAINTAINER,
          Gitlab::Access::OWNER
        ] }
    end
  end
end
