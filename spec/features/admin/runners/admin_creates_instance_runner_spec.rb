# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Admin creates an instance runner", :js, feature_category: :fleet_visibility do
  let_it_be(:admin) { create(:admin) }

  before do
    sign_in(admin)
    enable_admin_mode!(admin)
  end

  describe "admin runners page" do
    before do
      visit admin_runners_path
    end

    it 'displays a create button' do
      expect(page).to have_link s_('Runner|New instance runner'), href: new_admin_runner_path
    end

    it_behaves_like "shows and resets runner registration token" do
      let(:dropdown_text) { s_('Runners|Register an instance runner') }
      let(:registration_token) { Gitlab::CurrentSettings.runners_registration_token }
    end
  end

  describe "create runner" do
    before do
      visit new_admin_runner_path
    end

    it_behaves_like 'creates runner and shows register page' do
      let(:register_path_pattern) { register_admin_runner_path('.*') }
    end
  end
end
