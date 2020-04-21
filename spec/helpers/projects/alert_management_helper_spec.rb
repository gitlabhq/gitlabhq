# frozen_string_literal: true

require 'spec_helper'

describe Projects::AlertManagementHelper do
  include Gitlab::Routing.url_helpers

  let(:project) { create(:project) }

  describe '#alert_management_data' do
    let(:setting_path) { project_settings_operations_path(project) }

    let(:index_path) do
      project_alert_management_index_path(project, format: :json)
    end

    context 'without alert_managements_setting' do
      it 'returns frontend configuration' do
        expect(alert_management_data(project)).to eq(
          'index-path' => index_path,
          'enable-alert-management-path' => setting_path,
          "empty-alert-svg-path" => "/images/illustrations/alert-management-empty-state.svg"
        )
      end
    end
  end
end
