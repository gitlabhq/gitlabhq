# frozen_string_literal: true

module ContainerRegistry
  module Protection
    class Rule < ApplicationRecord
      enum delete_protected_up_to_access_level:
             Gitlab::Access.sym_options_with_owner.slice(:maintainer, :owner, :developer),
        _prefix: :delete_protected_up_to
      enum push_protected_up_to_access_level:
             Gitlab::Access.sym_options_with_owner.slice(:maintainer, :owner, :developer),
        _prefix: :push_protected_up_to

      belongs_to :project, inverse_of: :container_registry_protection_rules

      validates :container_path_pattern, presence: true, uniqueness: { scope: :project_id }, length: { maximum: 255 }
      validates :delete_protected_up_to_access_level, presence: true
      validates :push_protected_up_to_access_level, presence: true
    end
  end
end
