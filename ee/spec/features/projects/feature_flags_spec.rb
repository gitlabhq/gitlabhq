require 'spec_helper'

describe 'Feature Flags', :js do
  using RSpec::Parameterized::TableSyntax

  invalid_input_table = proc do
    'with space' | '' | 'Name can contain only'
    '<script>' | '' | 'Name can contain only'
    'x' * 100 | '' | 'Name is too long'
    'some-name' | 'y' * 1001 | 'Description is too long'
  end

  let(:user) {create(:user)}
  let(:project) {create(:project, namespace: user.namespace)}

  before do
    sign_in(user)
  end

  it 'shows empty state' do
    visit(project_feature_flags_path(project))

    expect_empty_state
  end

  context 'when creating a new feature flag' do
    context 'and input is valid' do
      where(:name, :description, :status) do
        'my-active-flag' | 'a new flag' | true
        'my-inactive-flag' | '' | false
      end

      with_them do
        it 'adds the feature flag to the table' do
          add_feature_flag(name, description, status)

          expect_feature_flag(name, description, status)
          expect(page).to have_selector '.flash-container', text: 'successfully created'
        end
      end
    end

    context 'and input is invalid' do
      where(:name, :description, :error_message, &invalid_input_table)

      with_them do
        it 'displays an error message' do
          add_feature_flag(name, description, false)

          # TODO: https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/7433#note_104442383
          # expect(current_path).to eq new_project_feature_flag_path(project)
          expect(page).to have_selector '.alert-danger', text: error_message
        end
      end
    end
  end

  context 'when editing a feature flag' do
    before do
      add_feature_flag('feature-flag-to-edit', 'with some description', false)
    end

    context 'and input is valid' do
      it 'updates the feature flag' do
        name = 'new-name'
        description = 'new description'

        edit_feature_flag('feature-flag-to-edit', name, description, true)

        expect_feature_flag(name, description, true)
        expect(page).to have_selector '.flash-container', text: 'successfully updated'
      end
    end

    context 'and input is invalid' do
      where(:name, :description, :error_message, &invalid_input_table)

      with_them do
        it 'displays an error message' do
          edit_feature_flag('feature-flag-to-edit', name, description, false)

          # TODO: https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/7433#note_104442383
          # expect(current_path).to eq new_project_feature_flag_path(project)
          expect(page).to have_selector '.alert-danger', text: error_message
        end
      end
    end
  end

  context 'when deleting a feature flag' do
    before do
      add_feature_flag('feature-flag-to-delete', 'with some description', false)
    end

    context 'and no feature flags are left' do
      it 'shows empty state' do
        visit(project_feature_flags_path(project))

        delete_feature_flag('feature-flag-to-delete')

        expect_empty_state
      end
    end

    context 'and there is a feature flag left' do
      before do
        add_feature_flag('another-feature-flag', '', true)
      end

      it 'shows feature flag table without deleted feature flag' do
        visit(project_feature_flags_path(project))

        delete_feature_flag('feature-flag-to-delete')

        expect_feature_flag('another-feature-flag', '', true)
      end
    end

    it 'does not delete if modal is cancelled' do
      visit(project_feature_flags_path(project))

      delete_feature_flag('feature-flag-to-delete', false)

      expect_feature_flag('feature-flag-to-delete', 'with some description', false)
    end
  end

  private

  def add_feature_flag(name, description, status)
    visit(new_project_feature_flag_path(project))

    fill_in 'Name', with: name
    fill_in 'Description', with: description

    if status
      check('Active')
    else
      uncheck('Active')
    end

    click_button 'Create feature flag'
  end

  def delete_feature_flag(name, confirm = true)
    delete_button = find('.gl-responsive-table-row', text: name).find('.btn-danger[title="Delete"]')
    delete_button.click

    within '.modal' do
      if confirm
        click_button 'Delete'
      else
        click_button 'Cancel'
      end
    end
  end

  def edit_feature_flag(old_name, new_name, new_description, new_status)
    visit(project_feature_flags_path(project))
    edit_button = find('.gl-responsive-table-row', text: old_name).find('.btn-default[title="Edit"]')
    edit_button.click

    fill_in 'Name', with: new_name
    fill_in 'Description', with: new_description

    if new_status
      check('Active')
    else
      uncheck('Active')
    end

    click_button 'Save changes'
  end

  def expect_empty_state
    expect(page).to have_text 'Get started with feature flags'
    expect(page).to have_selector('.btn-success', text: 'New Feature Flag')
    expect(page).to have_selector('.btn-primary.btn-inverted', text: 'Configure')
  end

  def expect_feature_flag(name, description, status)
    expect(current_path).to eq project_feature_flags_path(project)
    expect(page).to have_selector '.table-section .badge', text: status ? 'Active' : 'Inactive'
    expect(page).to have_selector '.table-section', text: name
    expect(page).to have_selector '.table-section', text: description
  end
end
