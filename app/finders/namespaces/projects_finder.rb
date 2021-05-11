# frozen_string_literal: true

# Namespaces::ProjectsFinder
#
# Used to filter Projects by set of params
#
# Arguments:
#   current_user
#   namespace
#   params:
#     sort: string
#     search: string
#     include_subgroups: boolean
#     ids: int[]
#
module Namespaces
  class ProjectsFinder
    def initialize(namespace: nil, current_user: nil, params: {})
      @namespace = namespace
      @current_user = current_user
      @params = params
    end

    def execute
      return Project.none if namespace.nil?

      collection = if params[:include_subgroups].present?
                     namespace.all_projects.with_route
                   else
                     namespace.projects.with_route
                   end

      filter_projects(collection)
    end

    private

    attr_reader :namespace, :params, :current_user

    def filter_projects(collection)
      collection = by_ids(collection)
      by_similarity(collection)
    end

    def by_ids(items)
      return items unless params[:ids].present?

      items.id_in(params[:ids])
    end

    def by_similarity(items)
      return items unless params[:search].present?

      if params[:sort] == :similarity
        items = items.sorted_by_similarity_desc(params[:search], include_in_select: true)
      end

      items.merge(Project.search(params[:search]))
    end
  end
end

Namespaces::ProjectsFinder.prepend_mod_with('Namespaces::ProjectsFinder')
