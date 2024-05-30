# frozen_string_literal: true

module Ci
  class BuildNameFinder
    MAX_PER_PAGE = 100

    def initialize(relation:, name:, project:, params: {})
      raise ArgumentError, 'Only Ci::Builds are name searchable' unless relation.klass == Ci::Build
      raise ArgumentError, "Offset Pagination is not supported" if relation.offset_value.present?

      @relation = relation
      @name = name
      @project = project
      @params = params
    end

    def execute
      return relation unless name.to_s.present?

      filter_by_name(relation)
    end

    private

    attr_reader :relation, :name, :project, :params

    # rubocop: disable CodeReuse/ActiveRecord -- Need specialized queries for database optimizations
    def filter_by_name(build_relation)
      build_name_relation = generate_build_name_relation(apply_pagination_cursor(build_relation))

      main_build_relation =
        Ci::Build.where("(id, partition_id) IN (?)", build_name_relation.select(:build_id, :partition_id))

      # Some callers (graphQL) will invert the ordering based on the relation and the params (asc)
      if params[:invert_ordering]
        main_build_relation.reorder(id: :desc)
      else
        apply_pagination_order(main_build_relation, :id)
      end
    end

    def generate_build_name_relation(build_subrelation)
      build_name_relation = Ci::BuildName
        .where(project_id: project.id)
        .pg_full_text_search_in_model(name)

      build_name_relation = apply_pagination_order(build_name_relation, :build_id)
      build_name_relation
        .where("(build_id, partition_id) IN (?)", build_subrelation.select(:id, :partition_id))
        .limit(MAX_PER_PAGE + 1)
    end

    # Ci::Builds main ordering is ID DESC which makes ordering reversed
    def apply_pagination_cursor(relation)
      return relation if params[:after].blank? && params[:before].blank?

      if params[:after]
        relation.id_before(Integer(params[:after]))
      else
        relation.id_after(Integer(params[:before]))
      end
    end

    def apply_pagination_order(relation, column)
      if params[:asc].present?
        relation.reorder(column => :asc)
      else
        relation.reorder(column => :desc)
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
