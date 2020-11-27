# frozen_string_literal: true

require "spec_helper"

RSpec.describe "User views incident" do
  let_it_be(:project) { create(:project_empty_repo, :public) }
  let_it_be(:user) { create(:user) }
  let_it_be(:incident) { create(:incident, project: project, description: "# Description header\n\n**Lorem** _ipsum_ dolor sit [amet](https://example.com)", author: user) }
  let_it_be(:note) { create(:note, noteable: incident, project: project, author: user) }

  before_all do
    project.add_developer(user)
  end

  before do
    sign_in(user)

    visit(project_issues_incident_path(project, incident))
  end

  it { expect(page).to have_header_with_correct_id_and_link(1, "Description header", "description-header") }

  it_behaves_like 'page meta description', ' Description header Lorem ipsum dolor sit amet'

  it 'shows the merge request and incident actions', :js, :aggregate_failures do
    click_button 'Incident actions'

    expect(page).to have_link('New incident', href: new_project_issue_path(project, { issuable_template: 'incident', issue: { issue_type: 'incident' } }))
    expect(page).to have_button('Create merge request')
    expect(page).to have_button('Close incident')
  end

  context 'when the project is archived' do
    before do
      project.update!(archived: true)
      visit(project_issues_incident_path(project, incident))
    end

    it 'hides the merge request and incident actions', :aggregate_failures do
      expect(page).not_to have_link('New incident')
      expect(page).not_to have_button('Create merge request')
      expect(page).not_to have_link('Close incident')
    end
  end

  describe 'user status' do
    subject { visit(project_issues_incident_path(project, incident)) }

    context 'when showing status of the author of the incident' do
      it_behaves_like 'showing user status' do
        let(:user_with_status) { user }
      end
    end

    context 'when showing status of a user who commented on an incident', :js do
      it_behaves_like 'showing user status' do
        let(:user_with_status) { user }
      end
    end

    context 'when status message has an emoji', :js do
      let_it_be(:message) { 'My status with an emoji' }
      let_it_be(:message_emoji) { 'basketball' }
      let_it_be(:status) { create(:user_status, user: user, emoji: 'smirk', message: "#{message} :#{message_emoji}:") }

      it 'correctly renders the emoji' do
        wait_for_requests

        tooltip_span = page.first(".user-status-emoji[title^='#{message}']")
        tooltip_span.hover

        wait_for_requests

        tooltip = page.find('.tooltip .tooltip-inner')

        page.within(tooltip) do
          expect(page).to have_emoji(message_emoji)
        end
      end
    end
  end
end
