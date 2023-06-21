# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Issues Feed', feature_category: :devops_reports do
  describe 'GET /issues' do
    let_it_be_with_reload(:user) do
      user = create(:user, email: 'private1@example.com')
      public_email = create(:email, :confirmed, user: user, email: 'public1@example.com')
      user.update!(public_email: public_email.email)
      user
    end

    let_it_be(:assignee) do
      user = create(:user, email: 'private2@example.com')
      public_email = create(:email, :confirmed, user: user, email: 'public2@example.com')
      user.update!(public_email: public_email.email)
      user
    end

    let_it_be(:group)    { create(:group) }
    let_it_be(:project)  { create(:project) }
    let_it_be(:issue)    { create(:issue, author: user, assignees: [assignee], project: project, due_date: Date.today) }
    let_it_be(:issuable) { issue } # "alias" for shared examples

    before_all do
      project.add_developer(user)
      group.add_developer(user)
    end

    RSpec.shared_examples 'an authenticated issue atom feed' do
      it 'renders atom feed with additional issue information' do
        expect(body).to have_selector('title', text: "#{project.name} issues")
        expect(body).to have_selector('due_date', text: issue.due_date)
      end
    end

    context 'when authenticated' do
      before do
        sign_in user
        visit project_issues_path(project, :atom)
      end

      it_behaves_like 'an authenticated issuable atom feed'
      it_behaves_like 'an authenticated issue atom feed'
    end

    context 'when authenticated via personal access token' do
      before do
        personal_access_token = create(:personal_access_token, user: user)

        visit project_issues_path(
          project,
          :atom,
          private_token: personal_access_token.token
        )
      end

      it_behaves_like 'an authenticated issuable atom feed'
      it_behaves_like 'an authenticated issue atom feed'
    end

    context 'when authenticated via feed token' do
      before do
        visit project_issues_path(
          project,
          :atom,
          feed_token: user.feed_token
        )
      end

      it_behaves_like 'an authenticated issuable atom feed'
      it_behaves_like 'an authenticated issue atom feed'
    end

    context 'when not authenticated' do
      before do
        visit project_issues_path(project, :atom)
      end

      context 'and the project is private' do
        it 'redirects to login page' do
          expect(page).to have_current_path(new_user_session_path)
        end
      end

      context 'and the project is public' do
        let_it_be(:project) { create(:project, :public) }
        let_it_be(:issue) { create(:issue, author: user, assignees: [assignee], project: project, due_date: Date.today) }
        let_it_be(:issuable) { issue } # "alias" for shared examples

        it_behaves_like 'an authenticated issuable atom feed'
        it_behaves_like 'an authenticated issue atom feed'
      end
    end

    it "renders atom feed with url parameters for project issues" do
      visit project_issues_path(project, :atom, feed_token: user.feed_token, state: 'opened', assignee_id: user.id)

      link = find('link[type="application/atom+xml"]')
      params = CGI.parse(URI.parse(link[:href]).query)

      expect(params).to include('feed_token' => [user.feed_token])
      expect(params).to include('state' => ['opened'])
      expect(params).to include('assignee_id' => [user.id.to_s])
    end

    it "renders atom feed with url parameters for group issues" do
      visit issues_group_path(group, :atom, feed_token: user.feed_token, state: 'opened', assignee_id: user.id)

      link = find('link[type="application/atom+xml"]')
      params = CGI.parse(URI.parse(link[:href]).query)

      expect(params).to include('feed_token' => [user.feed_token])
      expect(params).to include('state' => ['opened'])
      expect(params).to include('assignee_id' => [user.id.to_s])
    end
  end
end
