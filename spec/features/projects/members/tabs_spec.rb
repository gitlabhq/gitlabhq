# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Members > Tabs', :js, feature_category: :groups_and_projects do
  include Features::MembersHelpers
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, creator: user, namespace: user.namespace) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project_members) { create_list(:project_member, 2, project: project) }
  let_it_be(:access_requests) { create_list(:project_member, 2, :access_request, project: project) }
  let_it_be(:invites) { create_list(:project_member, 2, :invited, project: project) }
  let_it_be(:project_group_links) { create_list(:project_group_link, 2, project: project) }

  before do
    sign_in(user)
    visit project_project_members_path(project)
  end

  shared_examples 'active "Members" tab' do
    it 'displays "Members" tab' do
      expect(page).to have_selector('.nav-link.active', text: 'Members')
    end
  end

  context 'tabs' do
    where(:tab, :count) do
      'Members'             | 3
      'Pending invitations' | 2
      'Groups'              | 2
    end

    with_them do
      it "renders #{params[:tab]} tab" do
        expect(page).to have_selector('.nav-link', text: "#{tab} #{count}")
      end
    end

    it "renders Access requests tab", quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/448572' do
      expect(page).to have_selector('.nav-link', text: "Access requests 2")
    end

    context 'displays "Members" tab by default' do
      it_behaves_like 'active "Members" tab'
    end
  end

  context 'when searching "Groups"' do
    before do
      click_link 'Groups'

      fill_in_filtered_search 'Search groups', with: 'group'
    end

    it 'displays "Groups" tab', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/448573' do
      expect(page).to have_selector('.nav-link.active', text: 'Groups')
    end

    context 'and then searching "Members"' do
      before do
        click_link 'Members 3'

        fill_in_filtered_search 'Filter members', with: 'user'
      end

      it_behaves_like 'active "Members" tab'
    end
  end
end
