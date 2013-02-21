require 'spec_helper'

describe "Issues Feed" do
  describe "GET /issues" do
    let!(:user)     { create(:user) }
    let!(:project)  { create(:project, namespace: user.namespace) }
    let!(:issue)    { create(:issue, author: user, project: project) }

    before { project.team << [user, :developer] }

    context "when authenticated" do
      it "should render atom feed" do
        login_with user
        visit project_issues_path(project, :atom)

        page.response_headers['Content-Type'].should have_content("application/atom+xml")
        page.body.should have_selector("title", text: "#{project.name} issues")
        page.body.should have_selector("author email", text: issue.author_email)
        page.body.should have_selector("entry summary", text: issue.title)
      end
    end

    context "when authenticated via private token" do
      it "should render atom feed" do
        visit project_issues_path(project, :atom, private_token: user.private_token)

        page.response_headers['Content-Type'].should have_content("application/atom+xml")
        page.body.should have_selector("title", text: "#{project.name} issues")
        page.body.should have_selector("author email", text: issue.author_email)
        page.body.should have_selector("entry summary", text: issue.title)
      end
    end
  end
end
