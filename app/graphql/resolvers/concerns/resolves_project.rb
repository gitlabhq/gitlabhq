# frozen_string_literal: true

module ResolvesProject
  # Accepts EITHER one of
  #  - full_path: String (see Project#full_path)
  #  - project_id: GlobalID. Arguments should be typed as: `::Types::GlobalIDType[Project]`
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
