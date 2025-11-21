# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project navbar', :with_license, :js, feature_category: :groups_and_projects do
  include NavbarStructureHelper
  include WaitForRequests

  include_context 'project navbar structure'

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, namespace: user.namespace) }

  before_all do
    project.update!(duo_remote_flows_enabled: true)
  rescue StandardError
    nil
  end

  before do
    stub_feature_flags(hide_incident_management_features: false)
    stub_feature_flags(visual_ci_editor: false)
    sign_in(user)

    stub_config(registry: { enabled: false })
    insert_package_nav
    insert_infrastructure_registry_nav(s_('Terraform|Terraform states'))
    insert_infrastructure_google_cloud_nav
    insert_infrastructure_aws_nav
    project.update!(service_desk_enabled: true)
    allow(::ServiceDesk).to receive(:supported?).and_return(true)
  end

  describe 'when hide_error_tracking_features is disabled' do
    before do
      stub_feature_flags(hide_error_tracking_features: false)
    end

    it_behaves_like 'verified navigation bar' do
      before do
        visit project_path(project)
      end
    end

    context 'when pages are available' do
      before do
        stub_config(pages: { enabled: true })

        insert_after_sub_nav_item(
          _('Model registry'),
          within: _('Deploy'),
          new_sub_nav_item_name: _('Pages')
        )

        visit project_path(project)
      end

      it_behaves_like 'verified navigation bar'
    end

    context 'when package registry is available' do
      before do
        stub_config(packages: { enabled: true })

        visit project_path(project)
      end

      it_behaves_like 'verified navigation bar'
    end

    context 'when container registry is available' do
      before do
        stub_config(registry: { enabled: true })

        insert_container_nav

        visit project_path(project)
      end

      it_behaves_like 'verified navigation bar'
    end

    context 'when harbor registry is available' do
      let_it_be(:harbor_integration) { create(:harbor_integration, project: project) }

      before do
        insert_harbor_registry_nav

        visit project_path(project)
      end

      it_behaves_like 'verified navigation bar'
    end
  end

  describe 'when hide_error_tracking_features is enabled' do
    context 'when error tracking feature flag is enabled' do
      before do
        remove_nav_item(_('Error Tracking'))

        visit project_path(project)
      end

      it_behaves_like 'verified navigation bar'
    end
  end
end
