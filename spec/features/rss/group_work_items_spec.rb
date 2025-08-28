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

    let_it_be(:group) { create(:group, :private) }
    let_it_be(:project) { create(:project, group: group) }

    let!(:work_item) { create(:work_item, author: user, project: project) }

    context 'when authenticated' do
      context 'with no referer' do
        it 'renders RSS feed' do
          sign_in user
          visit group_work_items_path(group, :atom)

          expect(response_headers['Content-Type']).to have_content('application/atom+xml')
          expect(body).to include('<?xml version="1.0" encoding="UTF-8"?>')
          expect(body).to include('<feed xmlns="http://www.w3.org/2005/Atom"')
          expect(body).to include("<title>#{group.name} work items</title>")
          expect(body).to include("<title>#{work_item.title}</title>")
        end
      end

      context 'with GitLab as the referer' do
        it 'renders RSS feed' do
          sign_in user
          page.driver.header('Referer', group_work_items_url(group, host: Settings.gitlab.base_url))
          visit group_work_items_path(group, :atom)

          expect(response_headers['Content-Type']).to have_content('application/atom+xml')
          expect(body).to include('<feed xmlns="http://www.w3.org/2005/Atom"')
          expect(body).to include("<title>#{group.name} work items</title>")
          expect(body).to include("<title>#{work_item.title}</title>")
        end
      end
    end

    context 'when authenticated via personal access token' do
      it 'renders RSS feed' do
        personal_access_token = create(:personal_access_token, user: user)

        visit group_work_items_path(group, :atom, private_token: personal_access_token.token)

        expect(response_headers['Content-Type']).to have_content('application/atom+xml')
        expect(body).to include('<feed xmlns="http://www.w3.org/2005/Atom"')
        expect(body).to include("<title>#{group.name} work items</title>")
        expect(body).to include("<title>#{work_item.title}</title>")
      end
    end

    context 'when authenticated via feed token' do
      it 'renders RSS feed' do
        visit group_work_items_path(group, :atom, feed_token: user.feed_token)

        expect(response_headers['Content-Type']).to have_content('application/atom+xml')
        expect(body).to include('<feed xmlns="http://www.w3.org/2005/Atom"')
        expect(body).to include("<title>#{group.name} work items</title>")
        expect(body).to include("<title>#{work_item.title}</title>")
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
        visit group_work_items_path(group, :atom, feed_token: user.feed_token)

        expect(body).to include('<title>test work item title</title>')
        expect(body).to include('<summary>test work item title</summary>')
        expect(body).to include('<content>test work item desc</content>')
        expect(body).to include("<title>#{group.name} work items</title>")
        expect(body).to include('<work_item_type>Issue</work_item_type>')
        expect(body).to include('<state>opened</state>')
      end
    end

    context 'with multiple work items from different projects' do
      let_it_be(:other_project) { create(:project, group: group) }

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
          project: other_project,
          title: 'second work item'
        )
      end

      context 'when the user has full permission to see work items in both projects' do
        before do
          other_project.add_developer(user) # rubocop:disable RSpec/BeforeAllRoleAssignment -- Does not work in before_all
        end

        it 'renders both work items' do
          visit group_work_items_path(group, :atom, feed_token: user.feed_token)

          expect(body).to include('<title>first work item</title>')
          expect(body).to include('<title>second work item</title>')
          expect(body.scan(/<entry>/).count).to eq(3)
        end
      end

      context 'when the user has permission to see work items in select projects' do
        it 'renders work items from the projects the user has visibility in' do
          visit group_work_items_path(group, :atom, feed_token: user.feed_token)

          expect(body).to include('<title>first work item</title>')
          expect(body).not_to include('<title>second work item</title>')
          expect(body.scan(/<entry>/).count).to eq(2)
        end
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
        visit group_work_items_path(group, :atom, feed_token: user.feed_token)

        expect(body).to include("<name>#{assignee.name}</name>")
        expect(body).to include("<email>#{assignee.public_email}</email>")
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
        visit group_work_items_path(group, :atom, feed_token: user.feed_token)

        expect(body).to include('<label>bug</label>')
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
        visit group_work_items_path(group, :atom, feed_token: user.feed_token)

        expect(body).to include('<milestone>v1.0</milestone>')
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
        visit group_work_items_path(group, :atom, feed_token: user.feed_token)

        expect(body).to include("<due_date>#{Date.tomorrow}</due_date>")
      end
    end

    context 'with sorted by priority' do
      it 'renders RSS feed' do
        visit group_work_items_path(group, :atom, sort: 'priority', feed_token: user.feed_token)

        expect(response_headers['Content-Type']).to have_content('application/atom+xml')
        expect(body).to include('<feed xmlns="http://www.w3.org/2005/Atom"')
        expect(body).to include("<title>#{group.name} work items</title>")
        expect(body).to include("<title>#{work_item.title}</title>")
      end
    end

    context 'when user cannot access project' do
      let(:unauthorized_user) { create(:user) }

      it 'returns not found' do
        sign_in unauthorized_user
        visit group_work_items_path(group, :atom)

        expect(page.status_code).to eq(404)
      end
    end
  end
end
