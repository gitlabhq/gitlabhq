# frozen_string_literal: true
require 'spec_helper'

describe 'User creates a project', :js do
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  context 'in a group with DEVELOPER_MAINTAINER_PROJECT_ACCESS project_creation_level' do
    let(:group) { create(:group, project_creation_level: ::EE::Gitlab::Access::DEVELOPER_MAINTAINER_PROJECT_ACCESS) }

    before do
      group.add_developer(user)
    end

    it 'creates a new project' do
      visit(new_project_path)

      fill_in :project_path, with: 'a-new-project'

      page.find('.js-select-namespace').click
      page.find("div[role='option']", text: group.full_path).click

      page.within('#content-body') do
        click_button('Create project')
      end

      expect(page).to have_content("Project 'a-new-project' was successfully created")

      project = Project.find_by(name: 'a-new-project')
      expect(project.namespace).to eq(group)
    end
  end
end
