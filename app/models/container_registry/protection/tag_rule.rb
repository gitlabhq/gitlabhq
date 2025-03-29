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

      scope :immutable, -> { where(immutable_where_conditions) }
      scope :mutable, -> { where.not(immutable_where_conditions) }

      scope :for_actions_and_access, ->(actions, access_level, include_immutable: true) do
        conditions = []

        conditions << arel_table[:minimum_access_level_for_push].gt(access_level) if actions.include?('push')
        conditions << arel_table[:minimum_access_level_for_delete].gt(access_level) if actions.include?('delete')

        if include_immutable && (actions & %w[push delete]).any?
          immutable_where_conditions.each { |column, value| conditions << arel_table[column].eq(value) }
        end

        where(conditions.reduce(:or))
      end

      scope :for_delete_and_access, ->(access_level, include_immutable: true) do
        for_actions_and_access(DELETE_ACTIONS, access_level, include_immutable:)
      end

      scope :tag_name_patterns_for_project, ->(project_id) do
        select(:tag_name_pattern).where(project_id: project_id)
      end

      scope :pluck_tag_name_patterns, ->(limit = MAX_TAG_RULES_PER_PROJECT) { limit(limit).pluck(:tag_name_pattern) }

      def self.immutable_where_conditions
        { minimum_access_level_for_push: nil, minimum_access_level_for_delete: nil }
      end

      def push_restricted?(access_level)
        return Feature.enabled?(:container_registry_immutable_tags, project) if immutable?

        Gitlab::Access.sym_options_with_admin[minimum_access_level_for_push.to_sym] > access_level
      end

      def delete_restricted?(access_level)
        return Feature.enabled?(:container_registry_immutable_tags, project) if immutable?

        Gitlab::Access.sym_options_with_admin[minimum_access_level_for_delete.to_sym] > access_level
      end

      def immutable?
        minimum_access_level_for_push.nil? && minimum_access_level_for_delete.nil?
      end

      private

      def validate_access_levels
        return unless minimum_access_level_for_delete.present? ^ minimum_access_level_for_push.present?

        errors.add(:base, _('Access levels should either both be present or both be nil'))
      end
    end
  end
end
