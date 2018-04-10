module GraphHelper
  def refs(repo, commit)
    refs = commit.ref_names(repo).join(' ')

    # append note count
    notes_count = @graph.notes[commit.id]
    refs << "[#{pluralize(notes_count, 'note')}]" if notes_count > 0

    refs
  end

  def parents_zip_spaces(parents, parent_spaces)
    ids = parents.map { |p| p.id }
    ids.zip(parent_spaces)
  end

  def success_ratio(counts)
    return 100 if counts[:failed].zero?

    ratio = (counts[:success].to_f / (counts[:success] + counts[:failed])) * 100
    ratio.to_i
  end
end
