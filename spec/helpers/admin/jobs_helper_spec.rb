# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::JobsHelper, feature_category: :continuous_integration do
  let_it_be(:user) { build_stubbed(:user, :admin) }

  before do
    allow(helper).to receive_messages(
      current_user: user,
      job_statuses: {}
    )
  end

  describe '#admin_jobs_app_data', :enable_admin_mode do
    subject(:data) { helper.admin_jobs_app_data }

    it 'contains the correct data' do
      expect(data).to include(
        job_statuses: {}.to_json,
        empty_state_svg_path: helper.image_path('illustrations/empty-state/empty-pipeline-md.svg'),
        url: cancel_all_admin_jobs_path,
        can_update_all_jobs: 'true'
      )
    end
  end
end
