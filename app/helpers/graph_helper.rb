module GraphHelper
  def get_refs(repo, commit)
    refs = ""
    refs += commit.ref_names(repo).join(" ")

    # append note count
    refs += "[#{@graph.notes[commit.id]}]" if @graph.notes[commit.id] > 0

    refs
  end

  def parents_zip_spaces(parents, parent_spaces)
    ids = parents.map { |p| p.id }
    ids.zip(parent_spaces)
  end
end
