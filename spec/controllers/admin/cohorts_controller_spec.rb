# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::CohortsController do
  let(:user) { create(:admin) }

  before do
    sign_in(user)
  end

  describe 'GET #index' do
    it_behaves_like 'tracking unique visits', :index do
      let(:target_id) { 'i_analytics_cohorts' }
    end
  end
end
