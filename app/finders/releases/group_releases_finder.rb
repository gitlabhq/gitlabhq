# frozen_string_literal: true
module Releases
  ##
  # The GroupReleasesFinder does not support all the options of ReleasesFinder
  # due to use of InOperatorOptimization for finding subprojects/subgroups
  #
  # order_by - only ordering by released_at is supported
  # filter by tag - currently not supported
  class GroupReleasesFinder
    include Gitlab::Utils::StrongMemoize

    attr_reader :parent, :current_user, :params

    def initialize(parent, current_user = nil, params = {})
      @parent = parent
      @current_user = current_user
      @params = params

      params[:order_by] ||= 'released_at'
      params[:sort] ||= 'desc'
      params[:page] ||= 0
      params[:per] ||= 30
    end

    def execute(preload: true)
      return Release.none unless Ability.allowed?(current_user, :read_release, parent)

      releases = get_releases(preload: preload)

      paginate_releases(releases)
    end

    private

    def include_subgroups?
      params.fetch(:include_subgroups, false)
    end

    def accessible_projects_scope
      if include_subgroups?
        Project.for_group_and_its_subgroups(parent)
      else
        parent.projects
      end
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def get_releases(preload: true)
      Gitlab::Pagination::Keyset::InOperatorOptimization::QueryBuilder.new(
        scope: releases_scope(preload: preload),
        array_scope: accessible_projects_scope.select(:id),
        array_mapping_scope: -> (project_id_expression) { Release.where(Release.arel_table[:project_id].eq(project_id_expression)) },
        finder_query: -> (order_by, id_expression) { Release.where(Release.arel_table[:id].eq(id_expression)) }
      )
      .execute
    end

    def releases_scope(preload: true)
      scope = Release.all
      scope = order_releases(scope)
      scope = scope.preloaded if preload
      scope
    end

    def order_releases(scope)
      scope.sort_by_attribute("released_at_#{params[:sort]}").order(id: params[:sort])
    end

    def paginate_releases(releases)
      releases.page(params[:page].to_i).per(params[:per])
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
