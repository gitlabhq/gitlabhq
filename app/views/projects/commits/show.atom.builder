xml.instruct!
xml.feed "xmlns" => "http://www.w3.org/2005/Atom", "xmlns:media" => "http://search.yahoo.com/mrss/" do
  xml.title   "#{@project.name}:#{@ref} commits"
  xml.link    href: namespace_project_commits_url(@project.namespace, @project, @ref, format: :atom, private_token: current_user.try(:private_token)), rel: "self", type: "application/atom+xml"
  xml.link    href: namespace_project_commits_url(@project.namespace, @project, @ref), rel: "alternate", type: "text/html"
  xml.id      namespace_project_commits_url(@project.namespace, @project, @ref)
  xml.updated @commits.first.committed_date.strftime("%Y-%m-%dT%H:%M:%SZ") if @commits.any?

  @commits.each do |commit|
    xml.entry do
      xml.id      namespace_project_commit_url(@project.namespace, @project, id: commit.id)
      xml.link    href: namespace_project_commit_url(@project.namespace, @project, id: commit.id)
      xml.title   truncate(commit.title, length: 80)
      xml.updated commit.committed_date.strftime("%Y-%m-%dT%H:%M:%SZ")
      xml.media   :thumbnail, width: "40", height: "40", url: image_url(avatar_icon(commit.author_email))
      xml.author do |author|
        xml.name commit.author_name
        xml.email commit.author_email
      end
      xml.summary gfm(commit.description)
    end
  end
end
