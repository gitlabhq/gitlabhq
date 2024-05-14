# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Alert management', :js, feature_category: :incident_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user, developer_of: project) }

  context 'when visiting the alert details page' do
    let!(:alert) { create(:alert_management_alert, :resolved, :with_fingerprint, title: 'dos-test', project: project, **options) }
    let(:options) { {} }

    before do
      sign_in(user)
    end

    context 'when actor has permission to see the alert' do
      let(:user) { developer }

      it 'shows the alert details' do
        visit(details_project_alert_management_path(project, alert))

        within('.alert-management-details-table') do
          expect(page).to have_content(alert.title)
        end
      end

      context 'when alert belongs to an environment' do
        let(:options) { { environment: environment } }
        let!(:environment) { create(:environment, name: 'production', project: project) }

        it 'shows the environment name' do
          visit(details_project_alert_management_path(project, alert))

          expect(page).to have_link(environment.name, href: project_environment_path(project, environment))
          within('.alert-management-details-table') do
            expect(page).to have_content(environment.name)
          end
        end
      end
    end
  end
end
