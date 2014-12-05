xml.instruct!
xml.feed "xmlns" => "http://www.w3.org/2005/Atom", "xmlns:media" => "http://search.yahoo.com/mrss/" do
  xml.title   "#{@user.name} issues"
  xml.link    :href => issues_dashboard_url(:atom, :private_token => @user.private_token), :rel => "self", :type => "application/atom+xml"
  xml.link    :href => issues_dashboard_url(:private_token => @user.private_token), :rel => "alternate", :type => "text/html"
  xml.id      issues_dashboard_url(:private_token => @user.private_token)
  xml.updated @issues.first.created_at.strftime("%Y-%m-%dT%H:%M:%SZ") if @issues.any?

  @issues.each do |issue|
    issue_to_atom(xml, issue)
  end
end

