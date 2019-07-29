# frozen_string_literal: true

require 'spec_helper'

describe 'Projects > Settings > User manages group links' do
  include Select2Helper

  let(:user) { create(:user) }
  let(:project) { create(:project, namespace: user.namespace) }
  let(:group_ops) { create(:group, name: 'Ops') }
  let(:group_market) { create(:group, name: 'Market', path: 'market') }

  before do
    project.add_maintainer(user)
    group_market.add_guest(user)
    sign_in(user)

    share_link = project.project_group_links.new(group_access: Gitlab::Access::MAINTAINER)
    share_link.group_id = group_ops.id
    share_link.save!

    visit(project_group_links_path(project))
  end

  it 'shows a list of groups' do
    page.within('.project-members-groups') do
      expect(page).to have_content('Ops')
      expect(page).not_to have_content('Market')
    end
  end

  it 'invites a group to a project', :js do
    click_link('Invite group')

    select2(group_market.id, from: '#link_group_id')
    select('Maintainer', from: 'link_group_access')

    click_button('Invite')

    page.within('.project-members-groups') do
      expect(page).to have_content('Market')
    end
  end
end
