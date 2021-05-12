# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Frequently visited items', :js do
  let_it_be(:user) { create(:user) }

  shared_examples 'combined_menu: feature flag examples' do
    before do
      sign_in(user)
    end

    context 'for projects' do
      let_it_be(:project) { create(:project, :public) }

      it 'increments localStorage counter when visiting the project' do
        pending_on_combined_menu_flag

        visit project_path(project)

        frequent_projects = nil

        wait_for('localStorage frequent-projects') do
          frequent_projects = page.evaluate_script("localStorage['#{user.username}/frequent-projects']")

          frequent_projects.present?
        end

        expect(Gitlab::Json.parse(frequent_projects)).to contain_exactly(a_hash_including('id' => project.id, 'frequency' => 1))
      end
    end

    context 'for groups' do
      let_it_be(:group) { create(:group, :public) }

      it 'increments localStorage counter when visiting the group' do
        pending_on_combined_menu_flag

        visit group_path(group)

        frequent_groups = nil

        wait_for('localStorage frequent-groups') do
          frequent_groups = page.evaluate_script("localStorage['#{user.username}/frequent-groups']")

          frequent_groups.present?
        end

        expect(Gitlab::Json.parse(frequent_groups)).to contain_exactly(a_hash_including('id' => group.id, 'frequency' => 1))
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
