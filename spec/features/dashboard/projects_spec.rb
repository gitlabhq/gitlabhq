require 'spec_helper'

RSpec.describe 'Dashboard Projects', feature: true do
  before do
    login_as(create :user)
    visit dashboard_projects_path
  end
  
  it_behaves_like "an autodiscoverable RSS feed with current_user's private token"
end
