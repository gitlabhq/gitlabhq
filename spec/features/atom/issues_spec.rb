require 'spec_helper'

describe 'Issues Feed'  do
  describe 'GET /issues' do
    let!(:user)     { create(:user, email: 'private1@example.com', public_email: 'public1@example.com') }
    let!(:assignee) { create(:user, email: 'private2@example.com', public_email: 'public2@example.com') }
    let!(:group)    { create(:group) }
    let!(:project)  { create(:project) }
    let!(:issue)    { create(:issue, author: user, assignees: [assignee], project: project) }

    before do
      project.add_developer(user)
      group.add_developer(user)
    end

    context 'when authenticated' do
      it 'renders atom feed' do
        sign_in user
        visit project_issues_path(project, :atom)

        expect(response_headers['Content-Type'])
          .to have_content('application/atom+xml')
        expect(body).to have_selector('title', text: "#{project.name} issues")
        expect(body).to have_selector('author email', text: issue.author_public_email)
        expect(body).to have_selector('assignees assignee email', text: issue.assignees.first.public_email)
        expect(body).to have_selector('assignee email', text: issue.assignees.first.public_email)
        expect(body).to have_selector('entry summary', text: issue.title)
      end
    end

    context 'when authenticated via personal access token' do
      it 'renders atom feed' do
        personal_access_token = create(:personal_access_token, user: user)

        visit project_issues_path(project, :atom,
                                            private_token: personal_access_token.token)

        expect(response_headers['Content-Type'])
          .to have_content('application/atom+xml')
        expect(body).to have_selector('title', text: "#{project.name} issues")
        expect(body).to have_selector('author email', text: issue.author_public_email)
        expect(body).to have_selector('assignees assignee email', text: issue.assignees.first.public_email)
        expect(body).to have_selector('assignee email', text: issue.assignees.first.public_email)
        expect(body).to have_selector('entry summary', text: issue.title)
      end
    end

    context 'when authenticated via RSS token' do
      it 'renders atom feed' do
        visit project_issues_path(project, :atom,
                                            rss_token: user.rss_token)

        expect(response_headers['Content-Type'])
          .to have_content('application/atom+xml')
        expect(body).to have_selector('title', text: "#{project.name} issues")
        expect(body).to have_selector('author email', text: issue.author_public_email)
        expect(body).to have_selector('assignees assignee email', text: issue.assignees.first.public_email)
        expect(body).to have_selector('assignee email', text: issue.assignees.first.public_email)
        expect(body).to have_selector('entry summary', text: issue.title)
      end
    end

    it "renders atom feed with url parameters for project issues" do
      visit project_issues_path(project,
                                          :atom, rss_token: user.rss_token, state: 'opened', assignee_id: user.id)

      link = find('link[type="application/atom+xml"]')
      params = CGI.parse(URI.parse(link[:href]).query)

      expect(params).to include('rss_token' => [user.rss_token])
      expect(params).to include('state' => ['opened'])
      expect(params).to include('assignee_id' => [user.id.to_s])
    end

    it "renders atom feed with url parameters for group issues" do
      visit issues_group_path(group, :atom, rss_token: user.rss_token, state: 'opened', assignee_id: user.id)

      link = find('link[type="application/atom+xml"]')
      params = CGI.parse(URI.parse(link[:href]).query)

      expect(params).to include('rss_token' => [user.rss_token])
      expect(params).to include('state' => ['opened'])
      expect(params).to include('assignee_id' => [user.id.to_s])
    end
  end
end
