# frozen_string_literal: true

module GraphHelper
  def refs(repo, commit)
    refs = [commit.ref_names(repo).join(' ')]

    # append note count
    unless Feature.enabled?(:disable_network_graph_notes_count, @project, type: :experiment)
      notes_count = @graph.notes[commit.id]
      refs << "[#{pluralize(notes_count, 'note')}]" if notes_count > 0
    end

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
