module GraphHelper
  def get_refs(repo, commit)
    refs = ""
    # Commit::ref_names already strips the refs/XXX from important refs (e.g. refs/heads/XXX)
    # so anything leftover is internally used by GitLab
    commit_refs = commit.ref_names(repo).reject{ |name| name.starts_with?('refs/') }
    refs << commit_refs.join(' ')

    # append note count
    refs << "[#{@graph.notes[commit.id]}]" if @graph.notes[commit.id] > 0

    refs
  end

  def parents_zip_spaces(parents, parent_spaces)
    ids = parents.map { |p| p.id }
    ids.zip(parent_spaces)
  end

  def success_ratio(success_builds, failed_builds)
    failed_builds = failed_builds.count(:all)
    success_builds = success_builds.count(:all)

    return 100 if failed_builds.zero?

    ratio = (success_builds.to_f / (success_builds + failed_builds)) * 100
    ratio.to_i
  end
end
