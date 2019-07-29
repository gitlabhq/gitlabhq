# frozen_string_literal: true

require 'spec_helper'

describe 'Group' do
  let(:user) { create(:admin) }

  before do
    sign_in(user)
  end

  matcher :have_namespace_error_message do
    match do |page|
      page.has_content?("Group URL can contain only letters, digits, '_', '-' and '.'. Cannot start with '-' or end in '.', '.git' or '.atom'.")
    end
  end

  describe 'create a group' do
    before do
      visit new_group_path
    end

    describe 'as a non-admin' do
      let(:user) { create(:user) }

      it 'creates a group and persists visibility radio selection', :js do
        stub_application_setting(default_group_visibility: :private)

        fill_in 'Group name', with: 'test-group'
        find("input[name='group[visibility_level]'][value='#{Gitlab::VisibilityLevel::PUBLIC}']").click
        click_button 'Create group'

        group = Group.find_by(name: 'test-group')

        expect(group.visibility_level).to eq(Gitlab::VisibilityLevel::PUBLIC)
        expect(current_path).to eq(group_path(group))
        expect(page).to have_selector '.visibility-icon .fa-globe'
      end
    end

    describe 'with space in group path' do
      it 'renders new group form with validation errors' do
        fill_in 'Group URL', with: 'space group'
        click_button 'Create group'

        expect(current_path).to eq(groups_path)
        expect(page).to have_namespace_error_message
      end
    end

    describe 'with .atom at end of group path' do
      it 'renders new group form with validation errors' do
        fill_in 'Group URL', with: 'atom_group.atom'
        click_button 'Create group'

        expect(current_path).to eq(groups_path)
        expect(page).to have_namespace_error_message
      end
    end

    describe 'with .git at end of group path' do
      it 'renders new group form with validation errors' do
        fill_in 'Group URL', with: 'git_group.git'
        click_button 'Create group'

        expect(current_path).to eq(groups_path)
        expect(page).to have_namespace_error_message
      end
    end

    describe 'Mattermost team creation' do
      before do
        stub_mattermost_setting(enabled: mattermost_enabled)

        visit new_group_path
      end

      context 'Mattermost enabled' do
        let(:mattermost_enabled) { true }

        it 'displays a team creation checkbox' do
          expect(page).to have_selector('#group_create_chat_team')
        end

        it 'checks the checkbox by default' do
          expect(find('#group_create_chat_team')['checked']).to eq(true)
        end

        it 'updates the team URL on graph path update', :js do
          out_span = find('span[data-bind-out="create_chat_team"]', visible: false)

          expect(out_span.text).to be_empty

          fill_in('group_path', with: 'test-group')

          expect(out_span.text).to eq('test-group')
        end
      end

      context 'Mattermost disabled' do
        let(:mattermost_enabled) { false }

        it 'doesnt show a team creation checkbox if Mattermost not enabled' do
          expect(page).not_to have_selector('#group_create_chat_team')
        end
      end
    end
  end

  describe 'create a nested group', :js do
    let(:group) { create(:group, path: 'foo') }

    context 'as admin' do
      before do
        visit new_group_path(group, parent_id: group.id)
      end

      it 'creates a nested group' do
        fill_in 'Group name', with: 'bar'
        fill_in 'Group URL', with: 'bar'
        click_button 'Create group'

        expect(current_path).to eq(group_path('foo/bar'))
        expect(page).to have_content("Group 'bar' was successfully created.")
      end
    end

    context 'as group owner' do
      it 'creates a nested group' do
        user = create(:user)

        group.add_owner(user)
        sign_out(:user)
        sign_in(user)

        visit new_group_path(group, parent_id: group.id)

        fill_in 'Group name', with: 'bar'
        fill_in 'Group URL', with: 'bar'
        click_button 'Create group'

        expect(current_path).to eq(group_path('foo/bar'))
        expect(page).to have_content("Group 'bar' was successfully created.")
      end
    end
  end

  it 'checks permissions to avoid exposing groups by parent_id' do
    group = create(:group, :private, path: 'secret-group')

    sign_out(:user)
    sign_in(create(:user))
    visit new_group_path(parent_id: group.id)

    expect(page).not_to have_content('secret-group')
  end

  describe 'group edit', :js do
    let(:group) { create(:group, :public) }
    let(:path)  { edit_group_path(group) }
    let(:new_name) { 'new-name' }

    before do
      visit path
    end

    it_behaves_like 'dirty submit form', [{ form: '.js-general-settings-form', input: 'input[name="group[name]"]' },
                                          { form: '.js-general-settings-form', input: '#group_visibility_level_0' },
                                          { form: '.js-general-permissions-form', input: '#group_request_access_enabled' },
                                          { form: '.js-general-permissions-form', input: 'input[name="group[two_factor_grace_period]"]' }]

    it 'saves new settings' do
      page.within('.gs-general') do
        fill_in 'group_name', with: new_name
        click_button 'Save changes'
      end

      expect(page).to have_content 'successfully updated'
      expect(find('#group_name').value).to eq(new_name)

      page.within ".breadcrumbs" do
        expect(page).to have_content new_name
      end
    end

    it 'focuses confirmation field on remove group' do
      click_button('Remove group')

      expect(page).to have_selector '#confirm_name_input:focus'
    end

    it 'removes group' do
      expect { remove_with_confirm('Remove group', group.path) }.to change {Group.count}.by(-1)
      expect(group.members.all.count).to be_zero
      expect(page).to have_content "scheduled for deletion"
    end
  end

  describe 'group page with markdown description' do
    let(:group) { create(:group) }
    let(:path)  { group_path(group) }

    it 'parses Markdown' do
      group.update_attribute(:description, 'This is **my** group')

      visit path

      expect(page).to have_css('.home-panel-description-markdown > p > strong')
    end

    it 'passes through html-pipeline' do
      group.update_attribute(:description, 'This group is the :poop:')

      visit path

      expect(page).to have_css('.home-panel-description-markdown > p > gl-emoji')
    end

    it 'sanitizes unwanted tags' do
      group.update_attribute(:description, '# Group Description')

      visit path

      expect(page).not_to have_css('.home-panel-description-markdown h1')
    end

    it 'permits `rel` attribute on links' do
      group.update_attribute(:description, 'https://google.com/')

      visit path

      expect(page).to have_css('.home-panel-description-markdown a[rel]')
    end
  end

  describe 'group page with nested groups', :js do
    let!(:group) { create(:group) }
    let!(:nested_group) { create(:group, parent: group) }
    let!(:project) { create(:project, namespace: group) }
    let!(:path) { group_path(group) }

    it 'renders projects and groups on the page' do
      visit path
      wait_for_requests

      expect(page).to have_content(nested_group.name)
      expect(page).to have_content(project.name)
    end
  end

  def remove_with_confirm(button_text, confirm_with)
    click_button button_text
    fill_in 'confirm_name_input', with: confirm_with
    click_button 'Confirm'
  end
end
