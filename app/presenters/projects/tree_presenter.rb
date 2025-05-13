# frozen_string_literal: true

module Projects
  class TreePresenter < Gitlab::View::Presenter::Delegated
    presents Tree, as: :tree

    def permalink_path
      return unless tree.sha.present?

      project = tree.repository.project
      commit = tree.repository.commit(tree.sha)
      return unless commit

      path = tree.path.presence
      full_path = path.present? ? File.join(commit.sha, path) : commit.sha

      Gitlab::Routing.url_helpers.project_tree_path(project, full_path)
    end
  end
end
