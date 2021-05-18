# frozen_string_literal: true

module Ci
  class UnitTest < ApplicationRecord
    extend Gitlab::Ci::Model

    MAX_NAME_SIZE = 255
    MAX_SUITE_NAME_SIZE = 255

    validates :project, :key_hash, :name, :suite_name, presence: true

    has_many :unit_test_failures, class_name: 'Ci::UnitTestFailure'

    belongs_to :project

    scope :by_project_and_keys, -> (project, keys) { where(project_id: project.id, key_hash: keys) }
    scope :deletable, -> { where('NOT EXISTS (?)', Ci::UnitTestFailure.select(1).where("#{Ci::UnitTestFailure.table_name}.unit_test_id = #{table_name}.id")) }

    class << self
      def find_or_create_by_batch(project, unit_test_attrs)
        # Insert records first. Existing ones will be skipped.
        insert_all(build_insert_attrs(project, unit_test_attrs))

        # Find all matching records now that we are sure they all are persisted.
        by_project_and_keys(project, gather_keys(unit_test_attrs))
      end

      private

      def build_insert_attrs(project, unit_test_attrs)
        # NOTE: Rails 6.1 will add support for insert_all on relation so that
        # we will be able to do project.test_cases.insert_all.
        unit_test_attrs.map do |attrs|
          attrs.merge(
            project_id: project.id,
            name: attrs[:name].truncate(MAX_NAME_SIZE),
            suite_name: attrs[:suite_name].truncate(MAX_SUITE_NAME_SIZE)
          )
        end
      end

      def gather_keys(unit_test_attrs)
        unit_test_attrs.map { |attrs| attrs[:key_hash] }
      end
    end
  end
end
