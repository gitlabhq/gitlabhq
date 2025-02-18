# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Monitor dropdown sidebar', :js, feature_category: :shared do
  let_it_be_with_reload(:project) { create(:project, :internal, :repository) }
  let_it_be(:user) { create(:user) }

  let(:role) { nil }

  before do
    project.add_role(user, role) if role
    sign_in(user)

    project.update!(service_desk_enabled: true)
    allow(::ServiceDesk).to receive(:supported?).and_return(true)
  end

  shared_examples 'shows common Monitor menu item based on the access level' do
    using RSpec::Parameterized::TableSyntax

    let(:enabled) { Featurable::PRIVATE }
    let(:disabled) { Featurable::DISABLED }

    where(:monitor_level, :render) do
      ref(:enabled)  | true
      ref(:disabled) | false
    end

    with_them do
      it 'renders when expected to' do
        project.project_feature.update_attribute(:monitor_access_level, monitor_level)

        visit project_issues_path(project)

        click_button('Monitor')

        within_testid('super-sidebar') do
          if render
            expect(page).to have_link('Incidents')
          else
            expect(page).not_to have_link('Incidents', visible: :all)
          end
        end
      end
    end
  end

  context 'when user is not a member' do
    let(:access_level) { ProjectFeature::PUBLIC }

    before do
      project.project_feature.update_attribute(:monitor_access_level, access_level)
      visit project_issues_path(project)
      click_button('Monitor')
    end

    it 'has the correct `Monitor` and `Operate` menu items' do
      expect(page).to have_link('Incidents', href: project_incidents_path(project))

      click_button('Operate')

      expect(page).to have_link('Environments', href: project_environments_path(project))

      expect(page).not_to have_link('Alerts', href: project_alert_management_index_path(project), visible: :all)
      expect(page).not_to have_link('Error Tracking', href: project_error_tracking_index_path(project), visible: :all)
      expect(page).not_to have_link('Kubernetes clusters', href: project_clusters_path(project), visible: :all)
    end

    context 'when monitor project feature is PRIVATE' do
      let(:access_level) { ProjectFeature::PRIVATE }

      it 'does not show common items of the `Monitor` menu' do
        expect(page).not_to have_link('Error Tracking', href: project_incidents_path(project), visible: :all)
      end
    end

    context 'when monitor project feature is DISABLED' do
      let(:access_level) { ProjectFeature::DISABLED }

      it 'does not show the `Incidents` menu' do
        expect(page).not_to have_link('Error Tracking', href: project_incidents_path(project), visible: :all)
      end
    end
  end

  context 'when user has guest role' do
    let(:role) { :guest }

    it 'has the correct `Monitor` and `Operate` menu items' do
      visit project_issues_path(project)

      click_button('Monitor')

      expect(page).to have_link('Incidents', href: project_incidents_path(project))

      click_button('Operate')

      expect(page).to have_link('Environments', href: project_environments_path(project))

      expect(page).not_to have_link('Alerts', href: project_alert_management_index_path(project), visible: :all)
      expect(page).not_to have_link('Error Tracking', href: project_error_tracking_index_path(project), visible: :all)
      expect(page).not_to have_link('Kubernetes clusters', href: project_clusters_path(project), visible: :all)
    end

    it_behaves_like 'shows common Monitor menu item based on the access level'
  end

  context 'when user has reporter role' do
    let(:role) { :reporter }

    it 'has the correct `Monitor` and `Operate` menu items' do
      visit project_issues_path(project)

      click_button('Monitor')

      expect(page).to have_link('Incidents', href: project_incidents_path(project))
      expect(page).to have_link('Error Tracking', href: project_error_tracking_index_path(project))

      click_button('Operate')

      expect(page).to have_link('Environments', href: project_environments_path(project))

      expect(page).not_to have_link('Alerts', href: project_alert_management_index_path(project), visible: :all)
      expect(page).not_to have_link('Kubernetes clusters', href: project_clusters_path(project), visible: :all)
    end

    it_behaves_like 'shows common Monitor menu item based on the access level'
  end

  context 'when user has developer role' do
    let(:role) { :developer }

    it 'has the correct `Monitor` and `Operate` menu items' do
      visit project_issues_path(project)

      click_button('Monitor')

      expect(page).to have_link('Alerts', href: project_alert_management_index_path(project))
      expect(page).to have_link('Incidents', href: project_incidents_path(project))
      expect(page).to have_link('Error Tracking', href: project_error_tracking_index_path(project))

      click_button('Operate')

      expect(page).to have_link('Environments', href: project_environments_path(project))
      expect(page).to have_link('Kubernetes clusters', href: project_clusters_path(project))
    end

    it_behaves_like 'shows common Monitor menu item based on the access level'
  end

  context 'when user has maintainer role' do
    let(:role) { :maintainer }

    it 'has the correct `Monitor` and `Operate` menu items' do
      visit project_issues_path(project)

      click_button('Monitor')

      expect(page).to have_link('Alerts', href: project_alert_management_index_path(project))
      expect(page).to have_link('Incidents', href: project_incidents_path(project))
      expect(page).to have_link('Error Tracking', href: project_error_tracking_index_path(project))

      click_button('Operate')

      expect(page).to have_link('Environments', href: project_environments_path(project))
      expect(page).to have_link('Kubernetes clusters', href: project_clusters_path(project))
    end

    it_behaves_like 'shows common Monitor menu item based on the access level'
  end
end
