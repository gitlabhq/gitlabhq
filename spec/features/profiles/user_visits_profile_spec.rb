# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User visits their profile' do
  let_it_be_with_refind(:user) { create(:user) }

  before do
    sign_in(user)
  end

  it 'shows correct menu item' do
    visit(profile_path)

    expect(page).to have_active_navigation('Profile')
  end

  it 'shows profile info' do
    visit(profile_path)

    expect(page).to have_content "This information will appear on your profile"
  end

  it 'shows user readme' do
    create(:project, :repository, :public, path: user.username, namespace: user.namespace)

    visit(user_path(user))

    expect(find('.file-content')).to have_content('testme')
  end

  it 'hides empty user readme' do
    project = create(:project, :repository, :public, path: user.username, namespace: user.namespace)

    Files::UpdateService.new(
      project,
      user,
      start_branch: 'master',
      branch_name: 'master',
      commit_message: 'Update feature',
      file_path: 'README.md',
      file_content: ''
    ).execute

    visit(user_path(user))

    expect(page).not_to have_selector('.file-content')
  end

  context 'when user has groups' do
    let(:group) do
      create :group do |group|
        group.add_owner(user)
      end
    end

    let!(:project) do
      create(:project, :repository, namespace: group) do |project|
        create(:closed_issue_event, project: project)
        project.add_maintainer(user)
      end
    end

    def click_on_profile_picture
      find(:css, '.header-user-dropdown-toggle').click

      page.within ".header-user" do
        click_link user.username
      end
    end

    it 'shows user groups', :js do
      visit(profile_path)
      click_on_profile_picture

      page.within ".cover-block" do
        expect(page).to have_content user.name
        expect(page).to have_content user.username
      end

      page.within ".content" do
        click_link "Groups"
      end

      page.within "#groups" do
        expect(page).to have_content group.name
      end
    end
  end

  describe 'storage_enforcement_banner', :js do
    before do
      stub_feature_flags(namespace_storage_limit_bypass_date_check: false)
    end

    context 'with storage_enforcement_date set' do
      let_it_be(:storage_enforcement_date) { Date.today + 30 }

      before do
        allow_next_found_instance_of(Namespaces::UserNamespace) do |user_namespace|
          allow(user_namespace).to receive(:storage_enforcement_date).and_return(storage_enforcement_date)
        end
      end

      it 'displays the banner in the profile page' do
        visit(profile_path)
        expect_page_to_have_storage_enforcement_banner(storage_enforcement_date)
      end

      it 'does not display the banner if user has previously closed unless threshold has changed' do
        visit(profile_path)
        expect_page_to_have_storage_enforcement_banner(storage_enforcement_date)
        find('.js-storage-enforcement-banner [data-testid="close-icon"]').click
        page.refresh
        expect_page_not_to_have_storage_enforcement_banner

        storage_enforcement_date = Date.today + 13
        allow_next_found_instance_of(Namespaces::UserNamespace) do |user_namespace|
          allow(user_namespace).to receive(:storage_enforcement_date).and_return(storage_enforcement_date)
        end
        page.refresh
        expect_page_to_have_storage_enforcement_banner(storage_enforcement_date)
      end
    end

    context 'with storage_enforcement_date not set' do
      before do
        allow_next_found_instance_of(Namespaces::UserNamespace) do |user_namespace|
          allow(user_namespace).to receive(:storage_enforcement_date).and_return(nil)
        end
      end

      it 'does not display the banner in the group page' do
        visit(profile_path)
        expect_page_not_to_have_storage_enforcement_banner
      end
    end
  end

  def expect_page_to_have_storage_enforcement_banner(storage_enforcement_date)
    expect(page).to have_text "Effective #{storage_enforcement_date}, namespace storage limits will apply"
  end

  def expect_page_not_to_have_storage_enforcement_banner
    expect(page).not_to have_text "namespace storage limits will apply"
  end
end
