require 'spec_helper'

RSpec.describe 'Dashboard Activity', feature: true do
  before do
    login_as(create :user)
    visit activity_dashboard_path
  end

  it_behaves_like "it has an RSS button with current_user's RSS token"
  it_behaves_like "an autodiscoverable RSS feed with current_user's RSS token"
end
