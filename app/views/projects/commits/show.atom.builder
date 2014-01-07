xml.instruct!
xml.feed "xmlns" => "http://www.w3.org/2005/Atom", "xmlns:media" => "http://search.yahoo.com/mrss/" do
  xml.title   "Recent commits to #{@project.name}:#{@ref}"
  xml.link    :href => project_commits_url(@project, @ref, format: :atom), :rel => "self", :type => "application/atom+xml"
  xml.link    :href => project_commits_url(@project, @ref), :rel => "alternate", :type => "text/html"
  xml.id      project_commits_url(@project, @ref)
  xml.updated @commits.first.committed_date.strftime("%Y-%m-%dT%H:%M:%SZ") if @commits.any?

  @commits.each do |commit|
    xml.entry do
      xml.id      project_commit_url(@project, :id => commit.id)
      xml.link    :href => project_commit_url(@project, :id => commit.id)
      xml.title   truncate(commit.title, :length => 80)
      xml.updated commit.committed_date.strftime("%Y-%m-%dT%H:%M:%SZ")
      xml.media   :thumbnail, :width => "40", :height => "40", :url => avatar_icon(commit.author_email)
      xml.author do |author|
        xml.name commit.author_name
        xml.email commit.author_email
      end
      xml.summary gfm(commit.description)
    end
  end
end
