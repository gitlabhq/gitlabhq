# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin updates integrations settings', :js, :request_store, :enable_admin_mode,
  feature_category: :integrations do
  let_it_be(:admin) { create(:admin) }

  before do
    allow(Gitlab).to receive(:com?).and_return(false)
    sign_in(admin)
    visit integrations_admin_application_settings_path
  end

  it 'shows integrations table' do
    expect(page).to have_selector '[data-testid="inactive-integrations-table"]'
  end
end
