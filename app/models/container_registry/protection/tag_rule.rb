# frozen_string_literal: true

module ContainerRegistry
  module Protection
    class TagRule < ApplicationRecord
      self.table_name = 'container_registry_protection_tag_rules'

      ACCESS_LEVELS = Gitlab::Access.sym_options_with_admin.slice(:maintainer, :owner, :admin).freeze

      enum :minimum_access_level_for_delete, ACCESS_LEVELS, prefix: true
      enum :minimum_access_level_for_push, ACCESS_LEVELS, prefix: true

      belongs_to :project, inverse_of: :container_registry_protection_tag_rules

      validates :minimum_access_level_for_delete, :minimum_access_level_for_push, presence: true
      validates :tag_name_pattern, presence: true, uniqueness: { scope: :project_id }, length: { maximum: 100 }
      validates :tag_name_pattern, untrusted_regexp: true
    end
  end
end
