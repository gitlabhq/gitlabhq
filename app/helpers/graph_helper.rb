# frozen_string_literal: true

module GraphHelper
  def refs(repo, commit)
    refs = [commit.ref_names(repo).join(' ')]

    # append note count
    notes_count = @graph.notes[commit.id]
    refs << "[#{pluralize(notes_count, 'note')}]" if notes_count > 0

    refs.join
  end

  def parents_zip_spaces(parents, parent_spaces)
    ids = parents.map { |p| p.id }
    ids.zip(parent_spaces)
  end

  def success_ratio(counts)
    return 100 if counts[:failed] == 0

    ratio = (counts[:success].to_f / (counts[:success] + counts[:failed])) * 100
    ratio.to_i
  end

  def should_render_dora_charts
    false
  end
end

GraphHelper.prepend_mod_with('GraphHelper')
