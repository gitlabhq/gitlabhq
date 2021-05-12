# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Dashboard shortcuts', :js do
  shared_examples 'combined_menu: feature flag examples' do
    context 'logged in' do
      let(:user) { create(:user) }
      let(:project) { create(:project) }

      before do
        project.add_developer(user)
        sign_in(user)
        visit root_dashboard_path
      end

      it 'navigate to tabs' do
        pending_on_combined_menu_flag

        find('body').send_keys([:shift, 'I'])

        check_page_title('Issues')

        find('body').send_keys([:shift, 'M'])

        check_page_title('Merge requests')

        find('body').send_keys([:shift, 'T'])

        check_page_title('To-Do List')

        find('body').send_keys([:shift, 'G'])

        check_page_title('Groups')

        find('body').send_keys([:shift, 'P'])

        check_page_title('Projects')

        find('body').send_keys([:shift, 'A'])

        check_page_title('Activity')
      end
    end

    context 'logged out' do
      before do
        visit explore_root_path
      end

      it 'navigate to tabs' do
        pending_on_combined_menu_flag

        find('body').send_keys([:shift, 'G'])

        find('.nothing-here-block')
        expect(page).to have_content('No public groups')

        find('body').send_keys([:shift, 'S'])

        find('.nothing-here-block')
        expect(page).to have_content('No snippets found')

        find('body').send_keys([:shift, 'P'])

        find('.nothing-here-block')
        expect(page).to have_content('Explore public groups to find projects to contribute to.')
      end
    end

    def check_page_title(title)
      expect(find('.page-title')).to have_content(title)
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
