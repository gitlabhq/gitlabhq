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
    validate :check_sharding_key_id

    scope :scoped_runners, -> do
      where(arel_table[:runner_id].eq(Ci::Runner.arel_table[Ci::Runner.primary_key]))
    end

    scope :scoped_taggables, -> { scoped_runners }

    private

    def set_runner_type
      self.runner_type = runner.runner_type
    end

    def check_sharding_key_id
      if runner_type == 'instance_type'
        return if sharding_key_id.nil?

        errors.add(:sharding_key_id, 'instance_type runners must not have a sharding_key_id')
      else
        return if sharding_key_id.present?

        errors.add(:sharding_key_id, 'non-instance_type runners must have a sharding_key_id')
      end
    end
  end
end
