# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Members > Import project members', :js, feature_category: :groups_and_projects do
  include Features::MembersHelpers
  include ListboxHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:user_mike) { create(:user, name: 'Mike') }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) do
    create(:project, group: group).tap do |p|
      p.add_maintainer(user)
      p.add_developer(create(:user))
    end
  end

  let_it_be(:project2) do
    create(:project).tap do |p|
      p.add_maintainer(user)
      p.add_reporter(user_mike)
    end
  end

  before do
    sign_in(user)

    visit(project_project_members_path(project))
  end

  it 'imports a team from another project' do
    select_project(project2)
    submit_import

    expect(find_member_row(user_mike)).to have_content('Reporter')
  end

  it 'fails to import the other team when source project does not exist' do
    select_project(project2)
    submit_import { project2.destroy! }

    within import_project_members_modal_selector do
      expect(page).to have_content('404 Project Not Found')
    end
  end

  it 'fails to import some members' do
    group.add_owner(user_mike)

    select_project(project2)
    submit_import

    within import_project_members_modal_selector do
      expect(page).to have_content "The following 1 out of 2 members could not be added"
      expect(page).to have_content "@#{user_mike.username}: Access level should be greater than or equal to " \
                                   "Owner inherited membership from group #{group.name}"
    end
  end

  def select_project(source_project)
    click_on 'Import from a project'
    click_on 'Select a project'
    wait_for_requests

    select_listbox_item(source_project.name_with_namespace)
  end

  def submit_import
    yield if block_given? # rubocop:disable RSpec/AvoidConditionalStatements

    click_button 'Import project members'
    wait_for_requests
  end

  def import_project_members_modal_selector
    '[data-testid="import-project-members-modal"]'
  end
end
