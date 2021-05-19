# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Settings > User manages project members' do
  include Spec::Support::Helpers::Features::MembersHelpers
  include Select2Helper

  let(:group) { create(:group, name: 'OpenSource') }
  let(:project) { create(:project) }
  let(:project2) { create(:project) }
  let(:user) { create(:user) }
  let(:user_dmitriy) { create(:user, name: 'Dmitriy') }
  let(:user_mike) { create(:user, name: 'Mike') }

  before do
    project.add_maintainer(user)
    project.add_developer(user_dmitriy)
    sign_in(user)
  end

  it 'cancels a team member', :js do
    visit(project_project_members_path(project))

    page.within find_member_row(user_dmitriy) do
      click_button 'Remove member'
    end

    page.within('[role="dialog"]') do
      expect(page).to have_unchecked_field 'Also unassign this user from related issues and merge requests'
      click_button('Remove member')
    end

    visit(project_project_members_path(project))

    expect(members_table).not_to have_content(user_dmitriy.name)
    expect(members_table).not_to have_content(user_dmitriy.username)
  end

  it 'imports a team from another project', :js do
    project2.add_maintainer(user)
    project2.add_reporter(user_mike)

    visit(project_project_members_path(project))

    click_link('Import a project')

    select2(project2.id, from: '#source_project_id')
    click_button('Import project members')

    expect(find_member_row(user_mike)).to have_content('Reporter')
  end

  describe 'when the :invite_members_group_modal is disabled' do
    before do
      stub_feature_flags(invite_members_group_modal: false)
    end

    it 'imports a team from another project', :js do
      project2.add_maintainer(user)
      project2.add_reporter(user_mike)

      visit(project_project_members_path(project))

      page.within('.invite-users-form') do
        click_link('Import')
      end

      select2(project2.id, from: '#source_project_id')
      click_button('Import project members')

      expect(find_member_row(user_mike)).to have_content('Reporter')
    end
  end

  it 'shows all members of project shared group', :js do
    group.add_owner(user)
    group.add_developer(user_dmitriy)

    share_link = project.project_group_links.new(group_access: Gitlab::Access::MAINTAINER)
    share_link.group_id = group.id
    share_link.save!

    visit(project_project_members_path(project))

    click_link 'Groups'

    expect(find_group_row(group)).to have_content('Maintainer')
  end
end
