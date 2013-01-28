xml.instruct!
xml.feed "xmlns" => "http://www.w3.org/2005/Atom", "xmlns:media" => "http://search.yahoo.com/mrss/" do
  xml.title   "#{@user.name} issues"
  xml.link    :href => issues_dashboard_url(:atom, :private_token => @user.private_token), :rel => "self", :type => "application/atom+xml"
  xml.link    :href => issues_dashboard_url(:private_token => @user.private_token), :rel => "alternate", :type => "text/html"
  xml.id      issues_dashboard_url(:private_token => @user.private_token)
  xml.updated @issues.first.created_at.strftime("%Y-%m-%dT%H:%M:%SZ") if @issues.any?

  @issues.each do |issue|
    xml.entry do
      xml.id      project_issue_url(issue.project, issue)
      xml.link    :href => project_issue_url(issue.project, issue)
      xml.title   truncate(issue.title, :length => 80)
      xml.updated issue.created_at.strftime("%Y-%m-%dT%H:%M:%SZ")
      xml.media   :thumbnail, :width => "40", :height => "40", :url => gravatar_icon(issue.author_email)
      xml.author do |author|
        xml.name issue.author_name
        xml.email issue.author_email
      end
      xml.summary issue.title
    end
  end
end

