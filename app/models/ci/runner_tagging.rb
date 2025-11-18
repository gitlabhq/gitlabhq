# frozen_string_literal: true

module Ci
  class RunnerTagging < Ci::ApplicationRecord
    include BulkInsertSafe

    MAX_NAME_LENGTH = 255

    self.table_name = :ci_runner_taggings
    self.primary_key = :id

    ignore_column :name, remove_with: '18.7', remove_after: '2025-11-20'

    query_constraints :runner_id, :runner_type

    before_validation :set_runner_type, on: :create, if: -> { runner_type.nil? && runner }
    before_validation :copy_tag_name_from_tags, on: [:create, :update], if: -> { tag_name.nil? && tag.present? }

    enum :runner_type, Ci::Runner.runner_types

    scope :for_runner, ->(runner_id) { where(runner_id: runner_id) }

    belongs_to :runner, class_name: 'Ci::Runner', optional: false
    belongs_to :tag, class_name: 'Ci::Tag', optional: false

    validates :runner_type, presence: true
    validates :tag_name, presence: true, length: { maximum: MAX_NAME_LENGTH }
    validates :organization_id, presence: true, on: [:create, :update], unless: :instance_type?

    validate :no_organization_id, if: :instance_type?

    scope :scoped_runners, -> do
      where(arel_table[:runner_id].eq(Ci::Runner.arel_table[Ci::Runner.primary_key]))
    end

    scope :scoped_taggables, -> { scoped_runners }

    private

    def set_runner_type
      self.runner_type = runner.runner_type
    end

    def copy_tag_name_from_tags
      self.tag_name = tag.name
    end

    def no_organization_id
      return if organization_id.nil?

      errors.add(:organization_id, 'instance_type runners must not have an organization_id')
    end
  end
end
