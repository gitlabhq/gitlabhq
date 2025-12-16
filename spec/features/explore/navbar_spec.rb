# frozen_string_literal: true

require 'spec_helper'

RSpec.describe '"Explore" navbar', :js, :with_current_organization, feature_category: :navigation do
  include_context '"Explore" navbar structure'

  let_it_be(:user) { create(:user, organizations: [current_organization]) }

  it_behaves_like 'verified navigation bar' do
    before do
      sign_in(user)
      visit explore_projects_path
    end
  end
end
