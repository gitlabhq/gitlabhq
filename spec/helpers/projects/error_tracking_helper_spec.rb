# frozen_string_literal: true

require 'spec_helper'

describe Projects::ErrorTrackingHelper do
  include Gitlab::Routing.url_helpers

  set(:project) { create(:project) }

  describe '#error_tracking_data' do
    let(:setting_path) { project_settings_operations_path(project) }

    let(:index_path) do
      project_error_tracking_index_path(project, format: :json)
    end

    context 'without error_tracking_setting' do
      it 'returns frontend configuration' do
        expect(error_tracking_data(project)).to eq(
          'index-path' => index_path,
          'enable-error-tracking-link' => setting_path,
          'error-tracking-enabled' => 'false',
          "illustration-path" => "/images/illustrations/cluster_popover.svg"
        )
      end
    end

    context 'with error_tracking_setting' do
      let(:error_tracking_setting) do
        create(:project_error_tracking_setting, project: project)
      end

      context 'when enabled' do
        before do
          error_tracking_setting.update!(enabled: true)
        end

        it 'show error tracking enabled' do
          expect(error_tracking_data(project)).to include(
            'error-tracking-enabled' => 'true'
          )
        end
      end

      context 'when disabled' do
        before do
          error_tracking_setting.update!(enabled: false)
        end

        it 'show error tracking not enabled' do
          expect(error_tracking_data(project)).to include(
            'error-tracking-enabled' => 'false'
          )
        end
      end
    end
  end
end
