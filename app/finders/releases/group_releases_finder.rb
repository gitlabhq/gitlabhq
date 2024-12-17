# frozen_string_literal: true
module Releases
  ##
  # The GroupReleasesFinder does not support all the options of ReleasesFinder
  # due to use of InOperatorOptimization for finding subprojects/subgroups
  #
  # order_by - only ordering by released_at is supported
  # filter by tag - currently not supported
  # include_subgroups - always true for group releases finder
  class GroupReleasesFinder
    attr_reader :parent, :current_user, :params

    def initialize(parent, current_user = nil, params = {})
      @parent = parent
      @current_user = current_user
      @params = params

      params[:sort] ||= 'desc'
    end

    def execute(preload: true)
      return Release.none unless Ability.allowed?(current_user, :read_release, parent)

      releases = get_releases
      releases.preloaded if preload
      releases
    end

    private

    # rubocop: disable CodeReuse/ActiveRecord
    def get_releases
      Gitlab::Pagination::Keyset::InOperatorOptimization::QueryBuilder.new(
        scope: releases_scope,
        array_scope: Project.for_group_and_its_subgroups(parent).select(:id),
        array_mapping_scope: ->(project_id_expression) {
          Release.where(Release.arel_table[:project_id].eq(project_id_expression))
        },
        finder_query: ->(order_by, id_expression) { Release.where(Release.arel_table[:id].eq(id_expression)) }
      )
      .execute
    end

    def releases_scope
      Release.sort_by_attribute("released_at_#{params[:sort]}").order(id: params[:sort])
    end

    # rubocop: enable CodeReuse/ActiveRecord
  end
end
