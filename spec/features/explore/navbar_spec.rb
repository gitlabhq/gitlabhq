# frozen_string_literal: true

require 'spec_helper'

RSpec.describe '"Explore" navbar', :js, feature_category: :navigation do
  include_context '"Explore" navbar structure'

  it_behaves_like 'verified navigation bar' do
    before do
      visit explore_projects_path
    end
  end
end
