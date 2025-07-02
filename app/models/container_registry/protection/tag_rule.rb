# frozen_string_literal: true

module ContainerRegistry
  module Protection
    class TagRule < ApplicationRecord
      self.table_name = 'container_registry_protection_tag_rules'

      ACCESS_LEVELS = Gitlab::Access.sym_options_with_admin.slice(:maintainer, :owner, :admin).freeze
      MAX_TAG_RULES_PER_PROJECT = 5
      DELETE_ACTIONS = ['delete'].freeze

      enum :minimum_access_level_for_delete, ACCESS_LEVELS, prefix: true
      enum :minimum_access_level_for_push, ACCESS_LEVELS, prefix: true

      belongs_to :project, inverse_of: :container_registry_protection_tag_rules

      validates :tag_name_pattern, presence: true, uniqueness: { scope: :project_id }, length: { maximum: 100 }
      validates :tag_name_pattern, untrusted_regexp: true

      validate :validate_access_levels

      scope :mutable, -> { where.not(minimum_access_level_for_push: nil, minimum_access_level_for_delete: nil) }

      scope :for_actions_and_access, ->(actions, access_level) do
        where(base_conditions_for_actions_and_access(actions, access_level).reduce(:or))
      end

      scope :for_delete_and_access, ->(access_level) do
        for_actions_and_access(DELETE_ACTIONS, access_level)
      end

      scope :tag_name_patterns_for_project, ->(project_id) do
        select(:tag_name_pattern).where(project_id: project_id)
      end

      scope :pluck_tag_name_patterns, ->(limit = MAX_TAG_RULES_PER_PROJECT) { limit(limit).pluck(:tag_name_pattern) }

      def self.base_conditions_for_actions_and_access(actions, access_level)
        conditions = []
        conditions << arel_table[:minimum_access_level_for_push].gt(access_level) if actions.include?('push')
        conditions << arel_table[:minimum_access_level_for_delete].gt(access_level) if actions.include?('delete')
        conditions
      end

      def push_restricted?(access_level)
        Gitlab::Access.sym_options_with_admin[minimum_access_level_for_push.to_sym] > access_level
      end

      def delete_restricted?(access_level)
        Gitlab::Access.sym_options_with_admin[minimum_access_level_for_delete.to_sym] > access_level
      end

      def mutable?
        [minimum_access_level_for_push, minimum_access_level_for_delete].all?(&:present?)
      end

      def can_be_deleted?(user)
        return false if user.nil?
        return true if user.can_admin_all_resources?

        minimum_level_to_delete_rule <= project.team.max_member_access(user.id)
      end

      def matches_tag_name?(name)
        ::Gitlab::UntrustedRegexp.new(tag_name_pattern).match?(name)
      end

      private

      def validate_access_levels
        return if [minimum_access_level_for_delete, minimum_access_level_for_push].all?(&:present?)

        errors.add(:base, _('Access levels should both be present'))
      end

      def minimum_level_to_delete_rule
        Gitlab::Access::MAINTAINER
      end
    end
  end
end

ContainerRegistry::Protection::TagRule.prepend_mod
