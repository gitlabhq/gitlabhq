# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Frequently visited items', :js do
  include Spec::Support::Helpers::Features::TopNavSpecHelpers

  let_it_be(:user) { create(:user) }

  before do
    sign_in(user)
  end

  context 'for projects' do
    let_it_be(:project) { create(:project, :public) }

    it 'increments localStorage counter when visiting the project' do
      visit project_path(project)
      open_top_nav_projects

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
      visit group_path(group)
      open_top_nav_groups

      frequent_groups = nil

      wait_for('localStorage frequent-groups') do
        frequent_groups = page.evaluate_script("localStorage['#{user.username}/frequent-groups']")

        frequent_groups.present?
      end

      expect(Gitlab::Json.parse(frequent_groups)).to contain_exactly(a_hash_including('id' => group.id, 'frequency' => 1))
    end
  end
end
