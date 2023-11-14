# frozen_string_literal: true

require 'spec_helper'

RSpec.describe '"Explore" navbar', :js, feature_category: :navigation do
  include_context '"Explore" navbar structure'

  it_behaves_like 'verified navigation bar' do
    before do
      stub_feature_flags(global_ci_catalog: false)
      visit explore_projects_path
    end
  end

  context "with 'global_ci_catalog' enabled" do
    include_context '"Explore" navbar structure with global_ci_catalog FF'

    it_behaves_like 'verified navigation bar', global_ci_catalog: true do
      before do
        stub_feature_flags(global_ci_catalog: true)
        visit explore_projects_path
      end
    end
  end
end
