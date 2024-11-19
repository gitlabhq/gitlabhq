# frozen_string_literal: true

# Used to filter project topics by a set of params
#
# Arguments:
#   params:
#     search: string
module Projects
  class TopicsFinder
    def initialize(organization_id:, params: {})
      @params = params
      @organization_id = organization_id
    end

    def execute
      topics = Projects::Topic.for_organization(organization_id).order_by_non_private_projects_count
      topics = by_without_projects(topics)
      by_search(topics)
    end

    private

    attr_reader :current_user, :params, :organization_id

    def by_search(topics)
      return topics unless params[:search].present?

      topics.search(params[:search]).reorder_by_similarity(params[:search])
    end

    def by_without_projects(topics)
      return topics unless params[:without_projects]

      topics.without_assigned_projects
    end
  end
end
