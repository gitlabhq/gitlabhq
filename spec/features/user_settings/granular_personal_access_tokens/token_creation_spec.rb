# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User Settings > Granular personal access tokens > token creation',
  :with_current_organization, :js, feature_category: :system_access do
  include ListboxHelpers

  let_it_be(:user) { create(:user, :with_namespace) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, namespace: group) }

  before_all do
    group.add_owner(user)
  end

  before do
    stub_feature_flags(granular_personal_access_tokens: true)
    sign_in(user)
    visit granular_new_user_settings_personal_access_tokens_path
  end

  context 'when scoping to specific groups or projects' do
    it 'creates a token with the chosen resources and permissions' do
      fill_in 'Name', with: 'My Fine-Grained PAT'
      fill_in 'Description', with: 'My fine-grained PAT description'

      choose 'Only specific groups or projects that I\'m a member of'

      click_button 'Add group or project'
      select_listbox_item group.full_path, exact_text: true
      select_listbox_item project.full_path, exact_text: true

      within_testid('selected-namespaces') do
        expect(page).to have_text(group.full_path)
        expect(page).to have_text('0 subgroups, 1 projects')
        expect(page).to have_text(project.full_path)
      end

      page.within('.tab-pane.active') do
        click_button 'Toggle Groups category'
        check 'Avatar'

        click_button 'Toggle CI/CD category'
        check 'Runner'
      end

      # assert selected categories appear in order of their selection
      expect(page.find_all('[data-testid="selected-category-heading"]').map(&:text))
        .to eq(['Groups', 'CI/CD'])

      within(find_by_testid('selected-category', text: 'Groups')) do
        expect(page).to have_text('Avatar')
      end

      within(find_by_testid('selected-category', text: 'CI/CD')) do
        expect(page).to have_text('Runner')
      end

      within(find_by_testid('selected-resource', text: 'Runner')) do
        click_button 'Select permissions'
        select_listbox_item 'Read'
        select_listbox_item 'Assign'
      end

      within(find_by_testid('selected-resource', text: 'Avatar')) do
        click_button 'Select permissions'
        select_listbox_item 'Read'
      end

      click_on 'Generate token'

      expect(page).to have_text('Your new token has been created')
    end

    it 'allows removing a previously selected namespace' do
      fill_in 'Name', with: 'My Fine-Grained PAT'

      choose 'Only specific groups or projects that I\'m a member of'

      click_button 'Add group or project'
      select_listbox_item group.full_path, exact_text: true

      within_testid('selected-namespaces') do
        expect(page).to have_text(group.full_path)
        find_by_testid('remove-namespace').click
      end

      expect(page).not_to have_css('[data-testid="selected-namespaces"]')
    end
  end

  context 'when scoping to personal projects only' do
    it 'creates a token without a namespace selection' do
      fill_in 'Name', with: 'Personal-only PAT'
      fill_in 'Description', with: 'Covers only my personal projects'

      choose 'Only my personal projects'

      expect(page).not_to have_button 'Add group or project'

      page.within('.tab-pane.active') do
        click_button 'Toggle Groups category'
        check 'Avatar'
      end

      within(find_by_testid('selected-resource', text: 'Avatar')) do
        click_button 'Select permissions'
        select_listbox_item 'Read'
      end

      click_on 'Generate token'

      expect(page).to have_text('Your new token has been created')
    end
  end

  context 'when scoping to all memberships' do
    it 'creates a token covering all memberships' do
      fill_in 'Name', with: 'All-memberships PAT'
      fill_in 'Description', with: 'Covers everything I\'m a member of'

      choose 'All groups and projects that I\'m a member of'

      expect(page).not_to have_button 'Add group or project'

      page.within('.tab-pane.active') do
        click_button 'Toggle Groups category'
        check 'Avatar'
      end

      within(find_by_testid('selected-resource', text: 'Avatar')) do
        click_button 'Select permissions'
        select_listbox_item 'Read'
      end

      click_on 'Generate token'

      expect(page).to have_text('Your new token has been created')
    end
  end

  it 'creates a token spanning group, user, and global (instance) permissions' do
    fill_in 'Name', with: 'Multi-tab PAT'
    fill_in 'Description', with: 'PAT spanning namespace, user, and instance scopes'

    choose 'All groups and projects that I\'m a member of'

    page.within('.tab-pane.active') do
      click_button 'Toggle Groups category'
      check 'Avatar'
    end

    within(find_by_testid('selected-resource', text: 'Avatar')) do
      click_button 'Select permissions'
      select_listbox_item 'Read'
    end

    page.within('.gl-tabs-nav') do
      click_on 'User'
    end

    page.within('.tab-pane.active') do
      click_button 'Toggle System Access category'
      check 'User'
    end

    within(find_by_testid('selected-resource', text: 'User')) do
      click_button 'Select permissions'
      select_listbox_item 'Read'
    end

    page.within('.gl-tabs-nav') do
      click_on 'Global'
    end

    page.within('.tab-pane.active') do
      click_button 'CI/CD'
      check 'Cluster'
    end

    within(find_by_testid('selected-resource', text: 'Cluster')) do
      click_button 'Select permissions'
      select_listbox_item 'Read'
    end

    click_on 'Generate token'

    expect(page).to have_text('Your new token has been created')
  end

  context 'when selecting all resources in a category' do
    before do
      fill_in 'Name', with: 'Select-all PAT'
      fill_in 'Description', with: 'Token created via category select-all'

      choose 'All groups and projects that I\'m a member of'
    end

    it 'adds every resource in the category to the selection and creates a token' do
      check 'Groups'

      expect(selected_resource_names('Groups'))
        .to include('Avatar', 'Group', 'Member Role', 'SSH Certificate', 'Template')

      within(find_by_testid('selected-resource', text: 'Avatar')) do
        click_button 'Select permissions'
        select_listbox_item 'Read'
      end

      click_on 'Generate token'

      expect(page).to have_text('Your new token has been created')
    end

    it 'removes the category resources when unchecked' do
      check 'Groups'

      expect(page).to have_css('[data-testid="selected-resource"]')

      uncheck 'Groups'

      expect(page).to have_text('No resources added')
    end
  end

  context 'with expiration date' do
    context 'when an expiration date is optional' do
      before do
        allow(Gitlab::CurrentSettings).to receive(:require_personal_access_token_expiry?).and_return(false)

        visit granular_new_user_settings_personal_access_tokens_path
      end

      it 'lets the user clear the expiration date' do
        expect(find_field('Expiration date').value).not_to be_empty

        within_testid('expiration-date-field') { click_button 'Clear date' }

        expect(find_field('Expiration date').value).to be_empty
      end
    end

    context 'when an expiration date is required' do
      before do
        allow(Gitlab::CurrentSettings).to receive(:require_personal_access_token_expiry?).and_return(true)
        allow(PersonalAccessToken).to receive(:max_expiration_lifetime_in_days).and_return(365)

        visit granular_new_user_settings_personal_access_tokens_path
      end

      it 'does not allow clearing the expiration date' do
        expect(find_field('Expiration date').value).not_to be_empty

        within_testid('expiration-date-field') do
          expect(page).not_to have_button('Clear date')
        end
      end

      it 'pre-fills the expiration date with a default value' do
        expect(find_field('Expiration date').value).not_to be_empty
      end
    end
  end

  context 'with form validation' do
    it 'requires a name' do
      fill_in 'Description', with: 'has description but no name'
      choose 'All groups and projects that I\'m a member of'
      select_avatar_read_permission

      click_on 'Generate token'

      expect(page).to have_text('Add token name.')
      expect(page).not_to have_text('Your new token has been created')
    end

    it 'requires a description' do
      fill_in 'Name', with: 'has name but no description'
      choose 'All groups and projects that I\'m a member of'
      select_avatar_read_permission

      click_on 'Generate token'

      expect(page).to have_text('Add token description.')
      expect(page).not_to have_text('Your new token has been created')
    end

    it 'requires at least one resource with permissions' do
      fill_in 'Name', with: 'No permissions PAT'
      fill_in 'Description', with: 'No permissions PAT description'

      click_on 'Generate token'

      expect(page).to have_text('Add at least one resource with permissions.')
      expect(page).not_to have_text('Your new token has been created')
    end

    it 'requires a scope when namespace permissions are selected' do
      fill_in 'Name', with: 'No scope PAT'
      fill_in 'Description', with: 'No scope PAT description'

      select_avatar_read_permission

      click_on 'Generate token'

      expect(page).to have_text('Set group and project access.')
      expect(page).not_to have_text('Your new token has been created')
    end

    it 'requires at least one group or project when scoped to specific memberships' do
      fill_in 'Name', with: 'No namespace PAT'
      fill_in 'Description', with: 'No namespace PAT description'

      choose 'Only specific groups or projects that I\'m a member of'
      select_avatar_read_permission

      click_on 'Generate token'

      expect(page).to have_text('At least one group or project is required.')
      expect(page).not_to have_text('Your new token has been created')
    end
  end

  def select_avatar_read_permission
    page.within('.tab-pane.active') do
      click_button 'Toggle Groups category'
      check 'Avatar'
    end

    within(find_by_testid('selected-resource', text: 'Avatar')) do
      click_button 'Select permissions'
      select_listbox_item 'Read'
    end
  end

  def selected_resource_names(category_name)
    within(find_by_testid('selected-category', text: category_name)) do
      page.all('[data-testid="selected-resource-name"]').map(&:text)
    end
  end
end
