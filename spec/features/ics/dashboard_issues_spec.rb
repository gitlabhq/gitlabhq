# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Dashboard Issues Calendar Feed', feature_category: :team_planning do
  describe 'GET /issues' do
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
    let(:milestone) { create(:milestone, project_id: project.id, title: 'v1.0') }

    before do
      project.add_maintainer(user)
    end

    context 'when authenticated' do
      context 'with no referer' do
        it 'renders calendar feed' do
          sign_in user
          visit issues_dashboard_path(
            :ics,
            due_date: Issue::DueNextMonthAndPreviousTwoWeeks.name,
            sort: 'closest_future_date'
          )

          expect(response_headers['Content-Type']).to have_content('text/calendar')
          expect(body).to have_text('BEGIN:VCALENDAR')
        end
      end

      context 'with GitLab as the referer' do
        it 'renders calendar feed as text/plain' do
          sign_in user
          page.driver.header('Referer', issues_dashboard_url(host: Settings.gitlab.base_url))
          visit issues_dashboard_path(
            :ics,
            due_date: Issue::DueNextMonthAndPreviousTwoWeeks.name,
            sort: 'closest_future_date'
          )

          expect(response_headers['Content-Type']).to have_content('text/plain')
          expect(body).to have_text('BEGIN:VCALENDAR')
        end
      end

      context 'when filtered by milestone' do
        it 'renders calendar feed' do
          sign_in user
          visit issues_dashboard_path(
            :ics,
            due_date: Issue::DueNextMonthAndPreviousTwoWeeks.name,
            sort: 'closest_future_date',
            milestone_title: milestone.title
          )

          expect(response_headers['Content-Type']).to have_content('text/calendar')
          expect(body).to have_text('BEGIN:VCALENDAR')
        end
      end
    end

    context 'when authenticated via personal access token' do
      it 'renders calendar feed' do
        personal_access_token = create(:personal_access_token, user: user)

        visit issues_dashboard_path(
          :ics,
          due_date: Issue::DueNextMonthAndPreviousTwoWeeks.name,
          sort: 'closest_future_date',
          private_token: personal_access_token.token
        )

        expect(response_headers['Content-Type']).to have_content('text/calendar')
        expect(body).to have_text('BEGIN:VCALENDAR')
      end
    end

    context 'when authenticated via feed token' do
      it 'renders calendar feed' do
        visit issues_dashboard_path(
          :ics,
          due_date: Issue::DueNextMonthAndPreviousTwoWeeks.name,
          sort: 'closest_future_date',
          feed_token: user.feed_token
        )

        expect(response_headers['Content-Type']).to have_content('text/calendar')
        expect(body).to have_text('BEGIN:VCALENDAR')
      end
    end

    context 'issue with due date' do
      let!(:issue) do
        create(
          :issue,
          author: user,
          assignees: [assignee],
          project: project,
          title: 'test title',
          description: 'test desc',
          due_date: Date.tomorrow
        )
      end

      it 'renders issue fields' do
        visit issues_dashboard_path(
          :ics,
          due_date: Issue::DueNextMonthAndPreviousTwoWeeks.name,
          sort: 'closest_future_date',
          feed_token: user.feed_token
        )

        expect(body).to have_text("SUMMARY:test title (in #{project.full_path})")
        # line length for ics is 75 chars
        expected_description = "DESCRIPTION:Find out more at #{issue_url(issue)}".insert(75, ' ')
        expect(body).to have_text(expected_description)
        expect(body).to have_text("DTSTART;VALUE=DATE:#{Date.tomorrow.strftime('%Y%m%d')}")
        expect(body).to have_text("URI:#{issue_url(issue)}")
        expect(body).to have_text('TRANSP:TRANSPARENT')
      end
    end
  end
end
