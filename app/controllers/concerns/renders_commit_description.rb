module RendersCommitDescription
  def prepare_commit_descriptions_for_rendering(commit_descriptions)
    Banzai::CommitDescriptionRenderer.render(commit_descriptions, @project, current_user)

    commit_descriptions
  end
end
