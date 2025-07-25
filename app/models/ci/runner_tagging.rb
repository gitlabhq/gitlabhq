# frozen_string_literal: true

module Ci
  class RunnerTagging < Ci::ApplicationRecord
    include BulkInsertSafe

    self.table_name = :ci_runner_taggings
    self.primary_key = :id

    query_constraints :runner_id, :runner_type

    before_validation :set_runner_type, on: :create, if: -> { runner_type.nil? && runner }

    enum :runner_type, Ci::Runner.runner_types

    scope :for_runner, ->(runner_id) { where(runner_id: runner_id) }

    belongs_to :runner, class_name: 'Ci::Runner', optional: false
    belongs_to :tag, class_name: 'Ci::Tag', optional: false

    validates :runner_type, presence: true
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

    def no_organization_id
      return if organization_id.nil?

      errors.add(:organization_id, 'instance_type runners must not have an organization_id')
    end
  end
end
