# frozen_string_literal: true

module Ci
  class BuildNameFinder
    def initialize(relation:, name:, project:)
      raise ArgumentError, 'Only Ci::Builds are name searchable' unless relation.klass == Ci::Build

      @relation = relation
      @name = name
      @project = project
    end

    def execute
      return relation unless name.to_s.present?

      filter_by_name(relation)
    end

    private

    attr_reader :relation, :name, :project

    def limited_name_search_terms
      name.truncate_words(5, omission: '')
    end

    # rubocop: disable CodeReuse/ActiveRecord -- Need specialized queries for database optimizations
    def filter_by_name(build_relation)
      build_name_relation = Ci::BuildName
        .where(project_id: project.id)
        .pg_full_text_search_in_model(limited_name_search_terms)

      build_relation.where("(id, partition_id) IN (?)", build_name_relation.select(:build_id, :partition_id))
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
