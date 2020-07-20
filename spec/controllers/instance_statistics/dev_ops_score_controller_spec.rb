# frozen_string_literal: true

require 'spec_helper'

RSpec.describe InstanceStatistics::DevOpsScoreController do
  it_behaves_like 'instance statistics availability'

  describe 'GET #index' do
    let(:user) { create(:user) }

    before do
      sign_in(user)
    end

    it_behaves_like 'tracking unique visits', :index do
      let(:request_params) { {} }
      let(:target_id) { 'i_analytics_dev_ops_score' }
    end
  end
end
