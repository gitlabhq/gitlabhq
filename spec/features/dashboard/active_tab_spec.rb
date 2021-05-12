# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Dashboard Active Tab', :js do
  shared_examples 'combined_menu: feature flag examples' do
    before do
      sign_in(create(:user))
    end

    shared_examples 'page has active tab' do |title|
      it "#{title} tab" do
        pending_on_combined_menu_flag

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

  context 'with combined_menu: feature flag on' do
    let(:needs_rewrite_for_combined_menu_flag_on) { true }

    before do
      stub_feature_flags(combined_menu: true)
    end

    it_behaves_like 'combined_menu: feature flag examples'
  end

  context 'with combined_menu feature flag off' do
    let(:needs_rewrite_for_combined_menu_flag_on) { false }

    before do
      stub_feature_flags(combined_menu: false)
    end

    it_behaves_like 'combined_menu: feature flag examples'
  end

  def pending_on_combined_menu_flag
    pending 'https://gitlab.com/gitlab-org/gitlab/-/merge_requests/56587' if needs_rewrite_for_combined_menu_flag_on
  end
end
