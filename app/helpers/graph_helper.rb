module GraphHelper
  def get_refs(commit)
    refs = ""
    refs += commit.refs.collect{|r|r.name}.join(" ") if commit.refs

    # append note count
    notes = @project.notes.for_commit_id(commit.id)
    refs += "[#{notes.count}]" if notes.any?

    refs
  end

  def parents_zip_spaces(parents, parent_spaces)
    ids = parents.map { |p| p.id }
    ids.zip(parent_spaces)
  end
end
