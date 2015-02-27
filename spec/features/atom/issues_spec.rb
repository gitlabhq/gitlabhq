require 'spec_helper'

describe 'Issues Feed', feature: true  do
  describe 'GET /issues' do
    let!(:user)     { create(:user) }
    let!(:project)  { create(:project) }
    let!(:issue)    { create(:issue, author: user, project: project) }

    before { project.team << [user, :developer] }

    context 'when authenticated' do
      it 'should render atom feed' do
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
      it 'should render atom feed' do
        visit namespace_project_issues_path(project.namespace, project, :atom,
                                            private_token: user.private_token)

        expect(response_headers['Content-Type']).
          to have_content('application/atom+xml')
        expect(body).to have_selector('title', text: "#{project.name} issues")
        expect(body).to have_selector('author email', text: issue.author_email)
        expect(body).to have_selector('entry summary', text: issue.title)
      end
    end
  end
end
