require 'spec_helper'

describe 'Issues Feed', feature: true  do
  describe 'GET /issues' do
    let!(:user)     { create(:user) }
    let!(:group)    { create(:group) }
    let!(:project)  { create(:project) }
    let!(:issue)    { create(:issue, author: user, project: project) }

    before do
      project.team << [user, :developer]
      group.add_developer(user)
    end

    context 'when authenticated' do
      it 'renders atom feed' do
        login_with user
        visit namespace_project_issues_path(project.namespace, project, :atom)

        expect(response_headers['Content-Type']).
          to have_content('application/atom+xml')
        expect(body).to have_selector('title', text: "#{project.name} issues")
        expect(body).to have_selector('author email', text: issue.author_email)
        expect(body).to have_selector('entry summary', text: issue.title)
      end
    end

    context 'when authenticated via private token' do
      it 'renders atom feed' do
        visit namespace_project_issues_path(project.namespace, project, :atom,
                                            private_token: user.private_token)

        expect(response_headers['Content-Type']).
          to have_content('application/atom+xml')
        expect(body).to have_selector('title', text: "#{project.name} issues")
        expect(body).to have_selector('author email', text: issue.author_email)
        expect(body).to have_selector('entry summary', text: issue.title)
      end
    end

    it "renders atom feed with url parameters for project issues" do
      visit namespace_project_issues_path(project.namespace, project,
                                          :atom, private_token: user.private_token, state: 'opened', assignee_id: user.id)

      link = find('link[type="application/atom+xml"]')
      params = CGI::parse(URI.parse(link[:href]).query)

      expect(params).to include('private_token' => [user.private_token])
      expect(params).to include('state' => ['opened'])
      expect(params).to include('assignee_id' => [user.id.to_s])
    end

    it "renders atom feed with url parameters for group issues" do
      visit issues_group_path(group, :atom, private_token: user.private_token, state: 'opened', assignee_id: user.id)

      link = find('link[type="application/atom+xml"]')
      params = CGI::parse(URI.parse(link[:href]).query)

      expect(params).to include('private_token' => [user.private_token])
      expect(params).to include('state' => ['opened'])
      expect(params).to include('assignee_id' => [user.id.to_s])
    end
  end
end
