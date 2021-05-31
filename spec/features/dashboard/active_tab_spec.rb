# frozen_string_literal: true

require 'spec_helper'

# TODO: This entire spec file can be deleted once the combined_menu feature is fully rolled
#   out and the flag is removed, because it will then be irrelevant (there will be no more tabs).
#   Feature flag removal issue: https://gitlab.com/gitlab-org/gitlab/-/issues/324086
RSpec.describe 'Dashboard Active Tab', :js do
  shared_examples 'combined_menu: feature flag examples' do
    before do
      sign_in(create(:user))
    end

    shared_examples 'page has active tab' do |title|
      it "#{title} tab" do
        subject

        expect(page).to have_selector('.navbar-sub-nav li.active', count: 1)
        expect(find('.navbar-sub-nav li.active')).to have_content(title)
      end
    end

    context 'on dashboard projects' do
      it_behaves_like 'page has active tab', 'Projects' do
        subject { visit dashboard_projects_path }
      end
    end

    context 'on dashboard groups' do
      it_behaves_like 'page has active tab', 'Groups' do
        subject { visit dashboard_groups_path }
      end
    end
  end

  context 'with combined_menu feature flag off' do
    before do
      stub_feature_flags(combined_menu: false)
    end

    it_behaves_like 'combined_menu: feature flag examples'
  end
end
