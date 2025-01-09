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
#     include_archived: boolean
#     ids: int[]
#     with_issues_enabled: boolean
#     with_merge_requests_enabled: boolean
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

      container = if params[:include_sibling_projects] && namespace.is_a?(ProjectNamespace)
                    namespace.group
                  else
                    namespace
                  end

      collection = if params[:include_subgroups].present?
                     container.all_projects.with_route
                   else
                     container.projects.with_route
                   end

      collection = collection.not_aimed_for_deletion if params[:not_aimed_for_deletion].present?

      collection = filter_projects(collection)

      sort(collection)
    end

    private

    attr_reader :namespace, :params, :current_user

    def filter_projects(collection)
      collection = by_ids(collection)
      collection = by_archived(collection)
      collection = by_similarity(collection)
      by_feature_availability(collection)
    end

    def by_ids(items)
      return items unless params[:ids].present?

      items.id_in(params[:ids])
    end

    def by_archived(items)
      return items if Gitlab::Utils.to_boolean(params[:include_archived], default: true)

      items.non_archived
    end

    def by_similarity(items)
      return items unless params[:search].present?

      items.merge(Project.search(params[:search]))
    end

    def by_feature_availability(items)
      items = items.with_issues_available_for_user(current_user) if params[:with_issues_enabled].present?
      items = items.with_namespace_domain_pages if params[:with_namespace_domain_pages].present?
      if params[:with_merge_requests_enabled].present?
        items = items.with_merge_requests_available_for_user(current_user)
      end

      items
    end

    def sort(items)
      return items.projects_order_id_desc unless params[:sort]

      if params[:sort] == :similarity && params[:search].present?
        return items.sorted_by_similarity_desc(params[:search])
      end

      items.sort_by_attribute(params[:sort])
    end
  end
end

Namespaces::ProjectsFinder.prepend_mod_with('Namespaces::ProjectsFinder')
