# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project Work Items RSS Feed', feature_category: :team_planning do
  describe 'GET /work_items' do
    let!(:user) do
      user = create(:user, email: 'private1@example.com', developer_of: project)
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

    let_it_be(:project) { create(:project) }
    let!(:work_item) { create(:work_item, author: user, project: project) }

    context 'when authenticated' do
      context 'with no referer' do
        it 'renders RSS feed' do
          sign_in user
          visit project_work_items_path(project, :atom)

          expect(response_headers['Content-Type']).to have_content('application/atom+xml')
          expect(body).to include('<?xml version="1.0" encoding="UTF-8"?>')
          expect(body).to include('<feed xmlns="http://www.w3.org/2005/Atom"')
          expect(body).to have_selector('feed > title', text: "#{project.name} work items")
          expect(body).to have_selector('entry title', text: work_item.title)
        end
      end

      context 'with GitLab as the referer' do
        it 'renders RSS feed' do
          sign_in user
          page.driver.header('Referer', project_work_items_url(project, host: Settings.gitlab.base_url))
          visit project_work_items_path(project, :atom)

          expect(response_headers['Content-Type']).to have_content('application/atom+xml')
          expect(body).to include('<feed xmlns="http://www.w3.org/2005/Atom"')
          expect(body).to have_selector('feed > title', text: "#{project.name} work items")
          expect(body).to have_selector('entry title', text: work_item.title)
        end
      end
    end

    context 'when authenticated via personal access token' do
      it 'renders RSS feed' do
        personal_access_token = create(:personal_access_token, user: user)

        visit project_work_items_path(project, :atom, private_token: personal_access_token.token)

        expect(response_headers['Content-Type']).to have_content('application/atom+xml')
        expect(body).to include('<feed xmlns="http://www.w3.org/2005/Atom"')
        expect(body).to have_selector('feed > title', text: "#{project.name} work items")
        expect(body).to have_selector('entry title', text: work_item.title)
      end
    end

    context 'when authenticated via feed token' do
      it 'renders RSS feed' do
        visit project_work_items_path(project, :atom, feed_token: user.feed_token)

        expect(response_headers['Content-Type']).to have_content('application/atom+xml')
        expect(body).to include('<feed xmlns="http://www.w3.org/2005/Atom"')
        expect(body).to have_selector('feed > title', text: "#{project.name} work items")
        expect(body).to have_selector('entry title', text: work_item.title)
      end
    end

    context 'with work item with title and description' do
      let!(:work_item) do
        create(
          :work_item,
          author: user,
          project: project,
          title: 'test work item title',
          description: 'test work item desc'
        )
      end

      it 'renders work item fields' do
        visit project_work_items_path(project, :atom, feed_token: user.feed_token)

        expect(body).to have_selector('entry title[type="html"]', text: 'test work item title')
        expect(body).to have_selector('entry summary', text: 'test work item title')
        expect(body).to have_selector('entry content[type="html"]', text: 'test work item desc')
        expect(body).to have_selector('feed > title', text: "#{project.name} work items")
        expect(body).to have_selector('entry work_item_type', text: 'Issue')
        expect(body).to have_selector('entry state', text: 'opened')
      end
    end

    context 'with multiple work items' do
      let!(:work_item1) do
        create(
          :work_item,
          author: user,
          project: project,
          title: 'first work item'
        )
      end

      let!(:work_item2) do
        create(
          :work_item,
          author: user,
          project: project,
          title: 'second work item'
        )
      end

      it 'includes all work items' do
        visit project_work_items_path(project, :atom, feed_token: user.feed_token)

        expect(body).to have_selector('entry title', text: 'first work item')
        expect(body).to have_selector('entry title', text: 'second work item')
        expect(body).to have_selector('entry', count: 3)
      end
    end

    context 'with assignee' do
      let!(:work_item) do
        create(
          :work_item,
          author: user,
          assignees: [assignee],
          project: project,
          title: 'assigned work item'
        )
      end

      it 'includes assignee information' do
        visit project_work_items_path(project, :atom, feed_token: user.feed_token)

        expect(body).to have_selector('entry assignee name', text: assignee.name)
        expect(body).to have_selector('entry assignee email', text: assignee.public_email)
      end
    end

    context 'with labels' do
      let!(:label) { create(:label, project: project, title: 'bug') }
      let!(:work_item) do
        create(
          :work_item,
          author: user,
          project: project,
          title: 'labeled work item',
          labels: [label]
        )
      end

      it 'includes label information' do
        visit project_work_items_path(project, :atom, feed_token: user.feed_token)

        expect(body).to have_selector('entry label', text: 'bug')
      end
    end

    context 'with milestone' do
      let!(:milestone) { create(:milestone, project: project, title: 'v1.0') }
      let!(:work_item) do
        create(
          :work_item,
          author: user,
          project: project,
          title: 'milestone work item',
          milestone: milestone
        )
      end

      it 'includes milestone information' do
        visit project_work_items_path(project, :atom, feed_token: user.feed_token)

        expect(body).to have_selector('entry milestone', text: 'v1.0')
      end
    end

    context 'with due date' do
      let!(:work_item) do
        create(
          :work_item,
          author: user,
          project: project,
          title: 'work item with due date',
          due_date: Date.tomorrow
        )
      end

      it 'includes due date' do
        visit project_work_items_path(project, :atom, feed_token: user.feed_token)

        expect(body).to have_selector('entry due_date', text: Date.tomorrow.to_s)
      end
    end

    context 'with sorted by priority' do
      it 'renders RSS feed' do
        visit project_work_items_path(project, :atom, sort: 'priority', feed_token: user.feed_token)

        expect(response_headers['Content-Type']).to have_content('application/atom+xml')
        expect(body).to include('<feed xmlns="http://www.w3.org/2005/Atom"')
        expect(body).to have_selector('feed > title', text: "#{project.name} work items")
        expect(body).to have_selector('entry title', text: work_item.title)
      end
    end

    context 'when user cannot access project' do
      let(:unauthorized_user) { create(:user) }

      it 'returns not found' do
        sign_in unauthorized_user
        visit project_work_items_path(project, :atom)

        expect(page.status_code).to eq(404)
      end
    end
  end
end
