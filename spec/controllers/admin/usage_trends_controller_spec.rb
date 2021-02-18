# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::UsageTrendsController do
  let(:admin) { create(:user, :admin) }

  before do
    sign_in(admin)
  end

  describe 'GET #show' do
    it_behaves_like 'tracking unique visits', :index do
      let(:target_id) { 'i_analytics_instance_statistics' }
    end
  end
end
