# frozen_string_literal: true

require 'spec_helper'

describe 'Projects > Settings > User manages project members' do
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

  it 'cancels a team member' do
    visit(project_project_members_path(project))

    project_member = project.project_members.find_by(user_id: user_dmitriy.id)

    page.within("#project_member_#{project_member.id}") do
      click_link('Remove user from project')
    end

    visit(project_project_members_path(project))

    expect(page).not_to have_content(user_dmitriy.name)
    expect(page).not_to have_content(user_dmitriy.username)
  end

  it 'imports a team from another project' do
    project2.add_maintainer(user)
    project2.add_reporter(user_mike)

    visit(project_project_members_path(project))

    page.within('.invite-users-form') do
      click_link('Import')
    end

    select(project2.full_name, from: 'source_project_id')
    click_button('Import')

    project_member = project.project_members.find_by(user_id: user_mike.id)

    page.within("#project_member_#{project_member.id}") do
      expect(page).to have_content('Mike')
      expect(page).to have_content('Reporter')
    end
  end

  it 'shows all members of project shared group' do
    group.add_owner(user)
    group.add_developer(user_dmitriy)

    share_link = project.project_group_links.new(group_access: Gitlab::Access::MAINTAINER)
    share_link.group_id = group.id
    share_link.save!

    visit(project_project_members_path(project))

    page.within('.project-members-groups') do
      expect(page).to have_content('OpenSource')
      expect(first('.group_member')).to have_content('Maintainer')
    end
  end
end
