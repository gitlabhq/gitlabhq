# frozen_string_literal: true

module GraphHelper
  def refs(repo, commit)
    refs = [commit.ref_names(repo).join(' ')]

    refs.join
  end

  def parents_zip_spaces(parents, parent_spaces)
    ids = parents.map(&:id)
    ids.zip(parent_spaces)
  end

  def should_render_dora_charts
    false
  end

  def should_render_quality_summary
    false
  end
end

GraphHelper.prepend_mod_with('GraphHelper')
