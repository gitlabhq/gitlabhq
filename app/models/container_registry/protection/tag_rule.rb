# frozen_string_literal: true

module ContainerRegistry
  module Protection
    class TagRule < ApplicationRecord
      self.table_name = 'container_registry_protection_tag_rules'

      ACCESS_LEVELS = Gitlab::Access.sym_options_with_admin.slice(:maintainer, :owner, :admin).freeze
      MAX_TAG_RULES_PER_PROJECT = 5

      enum :minimum_access_level_for_delete, ACCESS_LEVELS, prefix: true
      enum :minimum_access_level_for_push, ACCESS_LEVELS, prefix: true

      belongs_to :project, inverse_of: :container_registry_protection_tag_rules

      validates :tag_name_pattern, presence: true, uniqueness: { scope: :project_id }, length: { maximum: 100 }
      validates :tag_name_pattern, untrusted_regexp: true

      validate :validate_access_levels

      scope :for_actions_and_access, ->(actions, access_level) {
        conditions = []
        conditions << arel_table[:minimum_access_level_for_push].gt(access_level) if actions.include?('push')
        conditions << arel_table[:minimum_access_level_for_delete].gt(access_level) if actions.include?('delete')

        where(conditions.reduce(:or))
      }

      def push_restricted?(access_level)
        Gitlab::Access.sym_options_with_admin[minimum_access_level_for_push.to_sym] > access_level
      end

      def delete_restricted?(access_level)
        Gitlab::Access.sym_options_with_admin[minimum_access_level_for_delete.to_sym] > access_level
      end

      private

      def validate_access_levels
        return unless minimum_access_level_for_delete.present? ^ minimum_access_level_for_push.present?

        errors.add(:base, _('Access levels should either both be present or both be nil'))
      end
    end
  end
end
