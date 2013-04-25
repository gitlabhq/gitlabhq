module GraphHelper
  def get_refs(commit)
    refs = ""
    refs += commit.refs.collect{|r|r.name}.join(" ") if commit.refs

    # append note count
    refs += "[#{@graph.notes[commit.id]}]" if @graph.notes[commit.id] > 0

    refs
  end

  def parents_zip_spaces(parents, parent_spaces)
    ids = parents.map { |p| p.id }
    ids.zip(parent_spaces)
  end
end
