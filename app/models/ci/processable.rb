# frozen_string_literal: true

module Ci
  class Processable < ::CommitStatus
    include Gitlab::Utils::StrongMemoize

    has_many :needs, class_name: 'Ci::BuildNeed', foreign_key: :build_id, inverse_of: :build

    accepts_nested_attributes_for :needs

    enum scheduling_type: { stage: 0, dag: 1 }, _prefix: true

    scope :preload_needs, -> { preload(:needs) }

    def self.select_with_aggregated_needs(project)
      return all unless Feature.enabled?(:ci_dag_support, project, default_enabled: true)

      aggregated_needs_names = Ci::BuildNeed
        .scoped_build
        .select("ARRAY_AGG(name)")
        .to_sql

      all.select(
        '*',
        "(#{aggregated_needs_names}) as aggregated_needs_names"
      )
    end

    validates :type, presence: true
    validates :scheduling_type, presence: true, on: :create, if: :validate_scheduling_type?

    def aggregated_needs_names
      read_attribute(:aggregated_needs_names)
    end

    def schedulable?
      raise NotImplementedError
    end

    def action?
      raise NotImplementedError
    end

    def when
      read_attribute(:when) || 'on_success'
    end

    def expanded_environment_name
      raise NotImplementedError
    end

    def scoped_variables_hash
      raise NotImplementedError
    end

    # scheduling_type column of previous builds/bridges have not been populated,
    # so we calculate this value on runtime when we need it.
    def find_legacy_scheduling_type
      strong_memoize(:find_legacy_scheduling_type) do
        needs.exists? ? :dag : :stage
      end
    end

    private

    def validate_scheduling_type?
      !importing? && Feature.enabled?(:validate_scheduling_type_of_processables, project)
    end
  end
end
