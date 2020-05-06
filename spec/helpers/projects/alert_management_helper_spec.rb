# frozen_string_literal: true

require 'spec_helper'

describe Projects::AlertManagementHelper do
  include Gitlab::Routing.url_helpers

  let_it_be(:project, reload: true) { create(:project) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:project_path) { project.full_path }

  describe '#alert_management_data' do
    let(:user_can_enable_alert_management) { false }
    let(:setting_path) { project_settings_operations_path(project) }

    before do
      allow(helper)
        .to receive(:can?)
        .with(current_user, :admin_operations, project)
        .and_return(user_can_enable_alert_management)
    end

    context 'without alert_managements_setting' do
      it 'returns index page configuration' do
        expect(alert_management_data(current_user, project)).to eq(
          'project-path' => project_path,
          'enable-alert-management-path' => setting_path,
          'empty-alert-svg-path' => '/images/illustrations/alert-management-empty-state.svg',
          'user-can-enable-alert-management' => 'false',
          'alert-management-enabled' => 'true'
        )
      end
    end
  end

  describe '#alert_management_detail_data' do
    let(:alert_id) { 1 }

    it 'returns detail page configuration' do
      expect(alert_management_detail_data(project_path, alert_id)).to eq(
        'alert-id' => alert_id,
        'project-path' => project_path
      )
    end
  end
end
