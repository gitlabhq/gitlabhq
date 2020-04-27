# frozen_string_literal: true

require 'spec_helper'

describe Projects::AlertManagementHelper do
  include Gitlab::Routing.url_helpers

  let_it_be(:project, reload: true) { create(:project) }
  let_it_be(:current_user) { create(:user) }

  describe '#alert_management_data' do
    let(:user_can_enable_alert_management) { false }
    let(:setting_path) { project_settings_operations_path(project) }

    let(:index_path) do
      project_alert_management_index_path(project, format: :json)
    end

    before do
      allow(helper)
        .to receive(:can?)
        .with(current_user, :admin_operations, project)
        .and_return(user_can_enable_alert_management)
    end

    context 'without alert_managements_setting' do
      it 'returns frontend configuration' do
        expect(alert_management_data(current_user, project)).to eq(
          'index-path' => index_path,
          'enable-alert-management-path' => setting_path,
          "empty-alert-svg-path" => "/images/illustrations/alert-management-empty-state.svg",
          'user-can-enable-alert-management' => 'false',
          'alert-management-enabled' => 'true'
        )
      end
    end
  end
end
