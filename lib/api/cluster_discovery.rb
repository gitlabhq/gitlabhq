# frozen_string_literal: true

module API
  class ClusterDiscovery < ::API::Base
    before do
      authenticate!
    end

    feature_category :deployment_management
    urgency :low

    desc 'Discover all descendant certificate-based clusters in a group' do
      detail 'This feature was introduced in GitLab 17.9. It will be removed in 18.0.'
      success Entities::DiscoveredClusters
      failure [
        { code: 403, message: 'Forbidden' }
      ]
      tags %w[clusters]
    end
    params do
      requires :group_id, type: Integer, desc: 'The group ID to find all certificate-based clusters in the hierarchy'
    end
    get '/discover-cert-based-clusters' do
      group = find_group!(params[:group_id])

      # Get all descendant groups
      groups = GroupsFinder.new(
        current_user,
        {
          parent: group,
          include_parent_descendants: true,
          min_access_level: Gitlab::Access::MAINTAINER
        }
      ).execute
      groups = [group] + groups

      # Get all descendant projects
      projects = GroupProjectsFinder.new(
        group: group,
        current_user: current_user,
        params: { min_access_level: Gitlab::Access::MAINTAINER },
        options: { include_subgroups: true }
      ).execute

      # rubocop: disable CodeReuse/ActiveRecord -- This entire endpoint is temporary and this implementation is the
      # boring solution, so let's just do the query directly here without "abstracting" it into the model or something.
      group_clusters = ::Clusters::Cluster.group_type
        .joins(:cluster_groups)
        .includes(cluster_groups: { group: :route })
        .where(cluster_groups: { group_id: Group.where(id: groups) })
        .group_by { |cluster| cluster.group.full_path }

      project_clusters = ::Clusters::Cluster.project_type
        .joins(:cluster_project)
        .includes(cluster_project: { project: :route })
        .where(cluster_projects: { project_id: Project.where(id: projects) })
        .group_by { |cluster| cluster.project.path_with_namespace }
      # rubocop: enable CodeReuse/ActiveRecord

      present({ groups: group_clusters, projects: project_clusters }, with: Entities::DiscoveredClusters)
    end
  end
end
