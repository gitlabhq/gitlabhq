# frozen_string_literal: true

class TreeEntryPresenter < Gitlab::View::Presenter::Delegated
  presents :tree

  def web_url
    Gitlab::Routing.url_helpers.project_tree_url(tree.repository.project, File.join(tree.commit_id, tree.path))
  end
end
