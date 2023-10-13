# frozen_string_literal: true

module Packages
  module Protection
    class Rule < ApplicationRecord
      enum package_type: Packages::Package.package_types.slice(:npm)
      enum push_protected_up_to_access_level:
             Gitlab::Access.sym_options_with_owner.slice(:developer, :maintainer, :owner),
        _prefix: :push_protected_up_to

      belongs_to :project, inverse_of: :package_protection_rules

      validates :package_name_pattern, presence: true, uniqueness: { scope: [:project_id, :package_type] },
        length: { maximum: 255 }
      validates :package_type, presence: true
      validates :push_protected_up_to_access_level, presence: true
    end
  end
end
