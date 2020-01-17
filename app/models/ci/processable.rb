# frozen_string_literal: true

module Ci
  class Processable < ::CommitStatus
    has_many :needs, class_name: 'Ci::BuildNeed', foreign_key: :build_id, inverse_of: :build

    accepts_nested_attributes_for :needs

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
  end
end
