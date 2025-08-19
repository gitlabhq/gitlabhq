# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project Work Items Calendar Feed', feature_category: :team_planning do
  describe 'GET /work_items' do
    let!(:user) do
      user = create(:user, email: 'private1@example.com')
      public_email = create(:email, :confirmed, user: user, email: 'public1@example.com')
      user.update!(public_email: public_email.email)
      user
    end

    let!(:assignee) do
      user = create(:user, email: 'private2@example.com')
      public_email = create(:email, :confirmed, user: user, email: 'public2@example.com')
      user.update!(public_email: public_email.email)
      user
    end

    let!(:project) { create(:project) }
    let!(:work_item) { create(:work_item, author: user, project: project) }

    before do
      stub_feature_flags(work_item_planning_view: true)

      project.add_developer(user)
    end

    context 'when authenticated' do
      context 'with no referer' do
        it 'renders calendar feed' do
          sign_in user
          visit project_work_items_path(project, :ics)

          expect(response_headers['Content-Type']).to have_content('text/calendar')
          expect(body).to have_text('BEGIN:VCALENDAR')
        end
      end

      context 'with GitLab as the referer' do
        it 'renders calendar feed as text/plain' do
          sign_in user
          page.driver.header('Referer', project_work_items_url(project, host: Settings.gitlab.base_url))
          visit project_work_items_path(project, :ics)

          expect(response_headers['Content-Type']).to have_content('text/plain')
          expect(body).to have_text('BEGIN:VCALENDAR')
        end
      end
    end

    context 'when authenticated via personal access token' do
      it 'renders calendar feed' do
        personal_access_token = create(:personal_access_token, user: user)

        visit project_work_items_path(project, :ics, private_token: personal_access_token.token)

        expect(response_headers['Content-Type']).to have_content('text/calendar')
        expect(body).to have_text('BEGIN:VCALENDAR')
      end
    end

    context 'when authenticated via feed token' do
      it 'renders calendar feed' do
        visit project_work_items_path(project, :ics, feed_token: user.feed_token)

        expect(response_headers['Content-Type']).to have_content('text/calendar')
        expect(body).to have_text('BEGIN:VCALENDAR')
      end
    end

    context 'with work item with due date' do
      let!(:work_item) do
        create(
          :work_item,
          author: user,
          project: project,
          title: 'test work item title',
          description: 'test work item desc',
          due_date: Date.tomorrow
        )
      end

      it 'renders work item fields' do
        visit project_work_items_path(project, :ics, feed_token: user.feed_token)

        expect(body).to have_text("SUMMARY:test work item title (in #{project.full_path})")
        # line length for ics is 75 chars
        expected_description = "DESCRIPTION:Find out more at #{project_work_item_url(project, work_item)}".insert(75,
          ' ')
        expect(body).to have_text(expected_description)
        expect(body).to have_text("DTSTART;VALUE=DATE:#{Date.tomorrow.strftime('%Y%m%d')}")
        expect(body).to have_text('TRANSP:TRANSPARENT')
      end
    end

    context 'with work item without due date' do
      let!(:work_item_no_due_date) do
        create(
          :work_item,
          author: user,
          project: project,
          title: 'work item without due date',
          due_date: nil
        )
      end

      it 'does not include work item without due date' do
        visit project_work_items_path(project, :ics, feed_token: user.feed_token)

        expect(body).not_to have_text('work item without due date')
      end
    end

    context 'with sorted by priority' do
      it 'renders calendar feed' do
        visit project_work_items_path(project, :ics, sort: 'priority', feed_token: user.feed_token)

        expect(response_headers['Content-Type']).to have_content('text/calendar')
        expect(body).to have_text('BEGIN:VCALENDAR')
      end
    end

    context 'with search by exact iid' do
      let!(:work_item_with_due_date) do
        create(
          :work_item,
          author: user,
          project: project,
          title: 'work item with iid search',
          due_date: Date.tomorrow
        )
      end

      let!(:other_work_item) do
        create(
          :work_item,
          author: user,
          project: project,
          title: 'other work item',
          due_date: Date.current
        )
      end

      it 'filters by iid when searching with # prefix' do
        visit project_work_items_path(project,
          :ics,
          search: "##{work_item_with_due_date.iid}",
          feed_token: user.feed_token
        )

        expect(response_headers['Content-Type']).to have_content('text/calendar')
        expect(body).to have_text('BEGIN:VCALENDAR')
        expect(body).to have_text('work item with iid search')
        expect(body).not_to have_text('other work item')
        expect(body.scan(/BEGIN:VEVENT/).count).to eq(1)
      end

      it 'includes all work items when search does not match iid format' do
        visit project_work_items_path(project, :ics, search: 'work item', feed_token: user.feed_token)

        expect(response_headers['Content-Type']).to have_content('text/calendar')
        expect(body).to have_text('BEGIN:VCALENDAR')
        expect(body).to have_text('work item with iid search')
        expect(body).to have_text('other work item')
        expect(body.scan(/BEGIN:VEVENT/).count).to eq(2)
      end
    end

    context 'with different work item states and default sorting' do
      let!(:opened_work_item) do
        create(
          :work_item,
          author: user,
          project: project,
          title: 'opened work item',
          state: 'opened',
          due_date: Date.tomorrow
        )
      end

      let!(:closed_work_item) do
        create(
          :work_item,
          author: user,
          project: project,
          title: 'closed work item',
          state: 'closed',
          due_date: Date.current
        )
      end

      it 'applies default sort for opened state (created_date)' do
        visit project_work_items_path(project, :ics, state: 'opened', feed_token: user.feed_token)

        expect(response_headers['Content-Type']).to have_content('text/calendar')
        expect(body).to have_text('BEGIN:VCALENDAR')
        expect(body).to have_text('opened work item')
        expect(body).not_to have_text('closed work item')
      end

      it 'applies default sort for closed state (updated_desc)' do
        visit project_work_items_path(project, :ics, state: 'closed', feed_token: user.feed_token)

        expect(response_headers['Content-Type']).to have_content('text/calendar')
        expect(body).to have_text('BEGIN:VCALENDAR')
        expect(body).to have_text('closed work item')
        expect(body).not_to have_text('opened work item')
      end

      it 'handles all states when no state filter is applied' do
        visit project_work_items_path(project, :ics, feed_token: user.feed_token)

        expect(response_headers['Content-Type']).to have_content('text/calendar')
        expect(body).to have_text('BEGIN:VCALENDAR')
        # Only opened items should appear by default (closed should be filtered out)
        expect(body).to have_text('opened work item')
        expect(body).not_to have_text('closed work item')
      end
    end

    context 'with multiple work items with due dates' do
      let!(:work_item1) do
        create(
          :work_item,
          author: user,
          project: project,
          title: 'first work item',
          due_date: Date.current
        )
      end

      let!(:work_item2) do
        create(
          :work_item,
          author: user,
          project: project,
          title: 'second work item',
          due_date: Date.tomorrow
        )
      end

      it 'includes all work items with due dates' do
        visit project_work_items_path(project, :ics, feed_token: user.feed_token)

        expect(body).to have_text('first work item')
        expect(body).to have_text('second work item')
        expect(body.scan(/BEGIN:VEVENT/).count).to eq(2)
      end
    end

    context 'when user cannot access project' do
      let(:unauthorized_user) { create(:user) }

      it 'returns not found' do
        sign_in unauthorized_user
        visit project_work_items_path(project, :ics)

        expect(page.status_code).to eq(404)
      end
    end
  end
end
