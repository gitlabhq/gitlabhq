# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group Work Items Calendar Feed', feature_category: :team_planning do
  describe 'GET /work_items' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, group: group) }
    let_it_be(:other_project) { create(:project, group: group) }
    let_it_be(:user) { create(:user, email: 'private1@example.com', developer_of: [project, other_project, group]) }

    context 'when authenticated' do
      context 'with no referer' do
        it 'renders calendar feed' do
          sign_in user
          visit group_work_items_path(group, :ics)

          expect(response_headers['Content-Type']).to have_content('text/calendar')
          expect(body).to have_text('BEGIN:VCALENDAR')
        end
      end

      context 'with GitLab as the referer' do
        it 'renders calendar feed as text/plain' do
          sign_in user
          page.driver.header('Referer', group_work_items_url(group, host: Settings.gitlab.base_url))
          visit group_work_items_path(group, :ics)

          expect(response_headers['Content-Type']).to have_content('text/plain')
          expect(body).to have_text('BEGIN:VCALENDAR')
        end
      end
    end

    context 'when authenticated via personal access token' do
      it 'renders calendar feed' do
        personal_access_token = create(:personal_access_token, user: user)

        visit group_work_items_path(group, :ics, private_token: personal_access_token.token)

        expect(response_headers['Content-Type']).to have_content('text/calendar')
        expect(body).to have_text('BEGIN:VCALENDAR')
      end
    end

    context 'when authenticated via feed token' do
      it 'renders calendar feed' do
        visit group_work_items_path(group, :ics, feed_token: user.feed_token)

        expect(response_headers['Content-Type']).to have_content('text/calendar')
        expect(body).to have_text('BEGIN:VCALENDAR')
      end
    end

    context 'with work items with a due date' do
      let_it_be(:work_item1) do
        create(
          :work_item,
          :issue,
          author: user,
          project: project,
          title: 'test title',
          description: 'test desc',
          due_date: Date.tomorrow
        )
      end

      let_it_be(:work_item2) do
        create(
          :work_item,
          :issue,
          author: user,
          project: other_project,
          title: 'other test title',
          description: 'other test desc',
          due_date: Date.tomorrow + 1.day
        )
      end

      it 'renders work item fields' do
        sign_in user
        visit group_work_items_path(group, :ics)

        expect(body).to have_text("SUMMARY:test title (in #{project.full_path})")
        # line length for ics is 75 chars
        work_item_1_expected_description = "DESCRIPTION:Find out more at " \
          "#{project_work_item_url(work_item1.project, work_item1)}".insert(75, ' ')
        expect(body).to have_text(work_item_1_expected_description)

        work_item_2_expected_description = "DESCRIPTION:Find out more at " \
          "#{project_work_item_url(work_item2.project, work_item2)}".insert(75, ' ')
        expect(body).to have_text(work_item_2_expected_description)

        expect(body).to have_text("DTSTART;VALUE=DATE:#{Date.tomorrow.strftime('%Y%m%d')}")
        expect(body).to have_text("DTSTART;VALUE=DATE:#{(Date.tomorrow + 1.day).strftime('%Y%m%d')}")

        expect(body).to have_text("URI:#{project_work_item_url(work_item1.project, work_item1)}")
        expect(body).to have_text("URI:#{project_work_item_url(work_item2.project, work_item2)}")

        expect(body).to have_text('TRANSP:TRANSPARENT')
      end
    end
  end
end
