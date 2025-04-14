# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Clusterable > Show page', feature_category: :deployment_management do
  include KubernetesHelpers

  let(:current_user) { create(:user) }
  let(:cluster_ingress_help_text_selector) { '.js-ingress-domain-help-text' }
  let(:hide_modifier_selector) { '.hide' }

  before do
    sign_in(current_user)
  end

  shared_examples 'show page' do
    it 'displays cluster type label' do
      visit cluster_path

      expect(page).to have_content(cluster_type_label)
    end

    it 'allow the user to set domain', :js do
      visit cluster_path

      within '.js-cluster-details-form' do
        fill_in('cluster_base_domain', with: 'test.com')
        click_on 'Save changes'
      end

      expect(page).to have_content('Kubernetes cluster was successfully updated.')
    end

    it 'does not show the environments tab' do
      visit cluster_path

      expect(page).not_to have_selector('[data-testid="cluster-environments-tab"]')
    end
  end

  shared_examples 'editing a GCP cluster' do
    before do
      visit cluster_path
    end

    it 'is not able to edit the name, API url, CA certificate nor token' do
      within('.js-provider-details') do
        cluster_name_field = find('.cluster-name')
        api_url_field = find('#cluster_platform_kubernetes_attributes_api_url')
        ca_certificate_field = find('#cluster_platform_kubernetes_attributes_ca_cert')
        token_field = find('#cluster_platform_kubernetes_attributes_token')

        expect(cluster_name_field).to be_readonly
        expect(api_url_field).to be_readonly
        expect(ca_certificate_field).to be_readonly
        expect(token_field).to be_readonly
      end
    end

    it 'displays GKE information' do
      click_link 'Advanced Settings'

      within('#advanced-settings-section') do
        expect(page).to have_content('Google Kubernetes Engine')
        expect(page).to have_content('Manage your Kubernetes cluster by visiting')
        expect_common_advanced_options
      end
    end
  end

  shared_examples 'editing a user-provided cluster' do
    before do
      stub_kubeclient_discover(cluster.platform.api_url)
      visit cluster_path
    end

    it 'is able to edit the name, API url, CA certificate and token' do
      within('.js-provider-details') do
        cluster_name_field = find('#cluster_name')
        api_url_field = find('#cluster_platform_kubernetes_attributes_api_url')
        ca_certificate_field = find('#cluster_platform_kubernetes_attributes_ca_cert')
        token_field = find('#cluster_platform_kubernetes_attributes_token')

        expect(cluster_name_field).not_to be_readonly
        expect(api_url_field).not_to be_readonly
        expect(ca_certificate_field).not_to be_readonly
        expect(token_field).not_to be_readonly
      end
    end

    it 'does not display GKE information' do
      click_link 'Advanced Settings'

      within('#advanced-settings-section') do
        expect(page).not_to have_content('Google Kubernetes Engine')
        expect(page).not_to have_content('Manage your Kubernetes cluster by visiting')
        expect_common_advanced_options
      end
    end
  end

  shared_examples 'migration tab' do
    describe 'migration tab' do
      before do
        stub_feature_flags(cluster_agent_migrations: true)
        visit cluster_path
        click_link 'Migrate'
      end

      it 'shows the migration form when no agent exists' do
        expect(page).to have_content('Migrate to GitLab Agent for Kubernetes')
        expect(page).to have_selector('.js-vue-project-select')
        expect(page).to have_field('Agent name')
        expect(page).to have_button('Create agent and migrate')
      end

      it 'shows the issue URL field and button as disabled when no agent exists' do
        expect(page).to have_button('Save migration issue', disabled: true)
        expect(page).to have_field('Migration issue URL', disabled: true)
      end

      context 'when agent exists' do
        let!(:agent) { create(:cluster_agent) }
        let!(:cluster_migration) do
          create(:cluster_agent_migration, cluster: cluster, agent: agent, agent_install_status: :success)
        end

        before do
          visit cluster_path
          click_link 'Migrate'
        end

        it 'shows agent information' do
          expect(page).to have_content('The agent connection is set up')
          expect(page).to have_content("#{agent.name}##{agent.id}")
          expect(page).to have_content(cluster_migration.project.full_name)
        end

        it 'shows the issue URL field' do
          expect(page).to have_field('Migration issue URL')
        end

        it 'can update the migration issue URL', :js do
          issue = create(:issue, project: configuration_project)
          issue_url = project_issue_url(configuration_project, issue)

          extractor_double = instance_double(Gitlab::ReferenceExtractor)
          allow(Gitlab::ReferenceExtractor).to receive(:new).and_return(extractor_double)
          allow(extractor_double).to receive(:analyze)
          allow(extractor_double).to receive(:issues).and_return([issue])

          fill_in 'Migration issue URL', with: issue_url
          click_button 'Save migration issue'

          expect(page).to have_content('Migration issue updated successfully')
        end
      end

      context 'when agent exists and issue is linked' do
        let!(:agent) { create(:cluster_agent) }
        let!(:issue) { create(:issue, project: configuration_project) }
        let!(:cluster_migration) do
          create(:cluster_agent_migration,
            cluster: cluster,
            agent: agent,
            agent_install_status: :success,
            issue: issue)
        end

        before do
          visit cluster_path
          click_link 'Migrate'
        end

        it 'shows the linked issue information' do
          expect(page).to have_content('Migration issue')
          expect(page).to have_link("#{issue.title} (##{issue.id})",
            href: project_issue_path(configuration_project, issue))
          expect(page).not_to have_field('Migration issue URL')
          expect(page).not_to have_button('Save migration issue')
        end
      end

      context 'with different installation states' do
        let!(:cluster_migration) { create(:cluster_agent_migration, cluster: cluster) }

        it 'shows in_progress state' do
          cluster_migration.update!(agent_install_status: :in_progress)
          visit cluster_path
          click_link 'Migrate'

          expect(page).to have_content('Installing agent in progress')
        end

        it 'shows error state' do
          cluster_migration.update!(agent_install_status: :error, agent_install_message: 'Failed to install')
          visit cluster_path
          click_link 'Migrate'

          expect(page).to have_content('Agent setup failed')
          expect(page).to have_content('Failed to install')
        end
      end

      describe 'creating an agent', :js do
        it 'creates agent successfully' do
          within_testid('cluster-migration-form') do
            select_from_project_select
            fill_in 'Agent name', with: 'test-agent'
            click_button 'Create agent and migrate'
          end

          expect(page).to have_content('Migrating cluster - initiated')
        end
      end
    end
  end

  context 'when clusterable is a project' do
    let(:clusterable) { create(:project) }
    let(:cluster_path) { project_cluster_path(clusterable, cluster) }
    let(:cluster) { create(:cluster, :provided_by_gcp, :project, projects: [clusterable]) }
    let!(:configuration_project) { clusterable }

    before do
      clusterable.add_maintainer(current_user)
    end

    it_behaves_like 'show page' do
      let(:cluster_type_label) { 'Project cluster' }
    end

    it_behaves_like 'editing a GCP cluster'

    it_behaves_like 'editing a user-provided cluster' do
      let(:cluster) { create(:cluster, :provided_by_user, :project, projects: [clusterable]) }
    end

    it_behaves_like 'migration tab'
  end

  context 'when clusterable is a group' do
    let(:clusterable) { create(:group) }
    let(:cluster_path) { group_cluster_path(clusterable, cluster) }
    let(:cluster) { create(:cluster, :provided_by_gcp, :group, groups: [clusterable]) }
    let!(:configuration_project) { create(:project, group: clusterable) }

    before do
      clusterable.add_maintainer(current_user)
    end

    it_behaves_like 'show page' do
      let(:cluster_type_label) { 'Group cluster' }
    end

    it_behaves_like 'editing a GCP cluster'

    it_behaves_like 'editing a user-provided cluster' do
      let(:cluster) { create(:cluster, :provided_by_user, :group, groups: [clusterable]) }
    end

    it_behaves_like 'migration tab'
  end

  context 'when clusterable is an instance' do
    let(:current_user) { create(:admin) }
    let(:cluster_path) { admin_cluster_path(cluster) }
    let(:cluster) { create(:cluster, :provided_by_gcp, :instance) }
    let!(:configuration_project) { create(:project) }

    before do
      enable_admin_mode!(current_user)
      configuration_project.add_owner(current_user)
      enable_admin_mode!(current_user)
    end

    it_behaves_like 'show page' do
      let(:cluster_type_label) { 'Instance cluster' }
    end

    it_behaves_like 'editing a GCP cluster'

    it_behaves_like 'editing a user-provided cluster' do
      let(:cluster) { create(:cluster, :provided_by_user, :instance) }
    end

    it_behaves_like 'migration tab'
  end

  private

  def expect_common_advanced_options
    aggregate_failures do
      expect(page).to have_content('Cluster management project')
      expect(page).to have_content('Clear cluster cache')
      expect(page).to have_content('Remove Kubernetes cluster integration')
    end
  end

  def select_from_project_select
    click_button('Search for project')
    wait_for_requests
    find('.gl-new-dropdown-item').click
  end
end
