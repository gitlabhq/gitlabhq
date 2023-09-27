# frozen_string_literal: true

class TreeEntryPresenter < Gitlab::View::Presenter::Delegated
  presents nil, as: :tree

  def web_url
    Gitlab::Routing.url_helpers.project_tree_url(tree.repository.project, ref_qualified_path,
      ref_type: tree.ref_type)
  end

  def web_path
    Gitlab::Routing.url_helpers.project_tree_path(tree.repository.project, ref_qualified_path,
      ref_type: tree.ref_type)
  end

  private

  def ref_qualified_path
    # If `ref_type` is present the commit_id will include the ref qualifier e.g. `refs/heads/`.
    # We only accept/return unqualified refs so we need to remove the qualifier from the `commit_id`.

    commit_id = ExtractsRef::RefExtractor.unqualify_ref(tree.commit_id, ref_type)

    File.join(commit_id, tree.path)
  end
end
