require 'rails_helper'

describe 'Geo read-only message' do
  include ::EE::GeoHelpers

  set(:user) { create(:user) }
  set(:primary) { create(:geo_node, :primary) }
  set(:secondary) { create(:geo_node) }

  before do
    sign_in(user)
  end

  it 'shows read-only banner when on a Geo secondary' do
    stub_current_geo_node(secondary)

    visit root_dashboard_path

    expect(page).to have_content('You are on a secondary (read-only) Geo node')
  end
end
