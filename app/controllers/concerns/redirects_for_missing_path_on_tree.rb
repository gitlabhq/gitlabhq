# frozen_string_literal: true

module RedirectsForMissingPathOnTree
  def redirect_to_tree_root_for_missing_path(project, ref, path, ref_type: nil)
    redirect_to project_tree_path(project, ref, ref_type: ref_type), notice: missing_path_on_ref(path, ref)
  end

  private

  def missing_path_on_ref(path, ref)
    format(_('"%{path}" did not exist on "%{ref}"'), path: truncate_path(path), ref: ref)
  end

  def truncate_path(path)
    path.reverse.truncate(60, separator: "/").reverse
  end
end
