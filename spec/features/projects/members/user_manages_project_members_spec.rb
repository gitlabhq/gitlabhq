# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Settings > User manages project members', :js, feature_category: :groups_and_projects do
  include Features::MembersHelpers
  include Spec::Support::Helpers::ModalHelpers
  include ListboxHelpers

  let(:group) { create(:group, name: 'OpenSource') }
  let(:project) { create(:project, :with_namespace_settings) }
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

    show_actions_for_username(user_dmitriy)
    click_button _('Remove member')

    within_modal do
      expect(page).to have_unchecked_field 'Also unassign this user from related issues and merge requests'
      click_button _('Remove member')
    end

    visit(project_project_members_path(project))

    expect(members_table).not_to have_content(user_dmitriy.name)
    expect(members_table).not_to have_content(user_dmitriy.username)
  end

  it 'shows all members of project shared group' do
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
