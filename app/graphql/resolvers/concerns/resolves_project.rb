# frozen_string_literal: true

module ResolvesProject
  def resolve_project(full_path: nil, project_id: nil)
    unless full_path.present? ^ project_id.present?
      raise ::Gitlab::Graphql::Errors::ArgumentError, 'Incompatible arguments: projectId, projectPath.'
    end

    if full_path.present?
      ::Gitlab::Graphql::Loaders::FullPathModelLoader.new(Project, full_path).find
    else
      ::GitlabSchema.object_from_id(project_id, expected_type: Project)
    end
  end
end
