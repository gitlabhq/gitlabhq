# frozen_string_literal: true

require "spec_helper"

RSpec.describe "User views incident", feature_category: :incident_management do
  let_it_be(:project) { create(:project_empty_repo, :public) }
  let_it_be(:guest) { create(:user, guest_of: project) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:user) { developer }
  let(:author) { developer }
  let(:description) { "# Description header\n\n**Lorem** _ipsum_ dolor sit [amet](https://example.com)" }
  let(:incident) { create(:incident, project: project, description: description, author: author) }

  before do
    sign_in(user)

    visit(incident_project_issues_path(project, incident))
  end

  specify do
    expect(page).to have_header_with_correct_id_and_link(1, 'Description header', 'description-header')
  end

  it_behaves_like 'page meta description', ' Description header Lorem ipsum dolor sit amet'

  describe 'user actions' do
    it 'shows the merge request and incident actions', :js, :aggregate_failures do
      expected_href = new_project_issue_path(
        project,
        issuable_template: 'incident',
        issue: { issue_type: 'incident' },
        add_related_issue: incident.iid
      )

      click_button 'Incident actions'

      expect(page).to have_link('New related incident', href: expected_href)
      expect(page).to have_button('Create merge request')
      expect(page).to have_button('Close incident')
    end

    context 'when user is guest' do
      let(:user) { guest }

      context 'and not author' do
        it 'shows incident actions', :js do
          click_button 'Incident actions'

          expect(page).to have_button 'Report abuse'
        end
      end
    end
  end
end
