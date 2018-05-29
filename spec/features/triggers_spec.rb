require 'spec_helper'

feature 'Triggers', :js do
  let(:trigger_title) { 'trigger desc' }
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:guest_user) { create(:user) }

  before do
    sign_in(user)

    @project = create(:project)
    @project.add_master(user)
    @project.add_master(user2)
    @project.add_guest(guest_user)

    visit project_settings_ci_cd_path(@project)
  end

  describe 'create trigger workflow' do
    scenario 'prevents adding new trigger with no description' do
      fill_in 'trigger_description', with: ''
      click_button 'Add trigger'

      # See if input has error due to empty value
      expect(page.find('form.gl-show-field-errors .gl-field-error')).to be_visible
    end

    scenario 'adds new trigger with description' do
      fill_in 'trigger_description', with: 'trigger desc'
      click_button 'Add trigger'

      # See if "trigger creation successful" message displayed and description and owner are correct
      expect(page.find('.flash-notice')).to have_content 'Trigger was created successfully.'
      expect(page.find('.triggers-list')).to have_content 'trigger desc'
      expect(page.find('.triggers-list .trigger-owner')).to have_content user.name
    end
  end

  describe 'edit trigger workflow' do
    let(:new_trigger_title) { 'new trigger' }

    scenario 'click on edit trigger opens edit trigger page' do
      create(:ci_trigger, owner: user, project: @project, description: trigger_title)
      visit project_settings_ci_cd_path(@project)

      # See if edit page has correct descrption
      find('a[title="Edit"]').send_keys(:return)
      expect(page.find('#trigger_description').value).to have_content 'trigger desc'
    end

    scenario 'edit trigger and save' do
      create(:ci_trigger, owner: user, project: @project, description: trigger_title)
      visit project_settings_ci_cd_path(@project)

      # See if edit page opens, then fill in new description and save
      find('a[title="Edit"]').send_keys(:return)
      fill_in 'trigger_description', with: new_trigger_title
      click_button 'Save trigger'

      # See if "trigger updated successfully" message displayed and description and owner are correct
      expect(page.find('.flash-notice')).to have_content 'Trigger was successfully updated.'
      expect(page.find('.triggers-list')).to have_content new_trigger_title
      expect(page.find('.triggers-list .trigger-owner')).to have_content user.name
    end

    scenario 'edit "legacy" trigger and save' do
      # Create new trigger without owner association, i.e. Legacy trigger
      create(:ci_trigger, owner: nil, project: @project)
      visit project_settings_ci_cd_path(@project)

      # See if the trigger can be edited and description is blank
      find('a[title="Edit"]').send_keys(:return)
      expect(page.find('#trigger_description').value).to have_content ''

      # See if trigger can be updated with description and saved successfully
      fill_in 'trigger_description', with: new_trigger_title
      click_button 'Save trigger'
      expect(page.find('.flash-notice')).to have_content 'Trigger was successfully updated.'
      expect(page.find('.triggers-list')).to have_content new_trigger_title
    end
  end

  describe 'trigger "Take ownership" workflow' do
    before do
      create(:ci_trigger, owner: user2, project: @project, description: trigger_title)
      visit project_settings_ci_cd_path(@project)
    end

    scenario 'button "Take ownership" has correct alert' do
      expected_alert = 'By taking ownership you will bind this trigger to your user account. With this the trigger will have access to all your projects as if it was you. Are you sure?'
      expect(page.find('a.btn-trigger-take-ownership')['data-confirm']).to eq expected_alert
    end

    scenario 'take trigger ownership' do
      # See if "Take ownership" on trigger works post trigger creation
      page.accept_confirm do
        first(:link, "Take ownership").send_keys(:return)
      end

      expect(page.find('.flash-notice')).to have_content 'Trigger was re-assigned.'
      expect(page.find('.triggers-list')).to have_content trigger_title
      expect(page.find('.triggers-list .trigger-owner')).to have_content user.name
    end
  end

  describe 'trigger "Revoke" workflow' do
    before do
      create(:ci_trigger, owner: user2, project: @project, description: trigger_title)
      visit project_settings_ci_cd_path(@project)
    end

    scenario 'button "Revoke" has correct alert' do
      expected_alert = 'By revoking a trigger you will break any processes making use of it. Are you sure?'
      expect(page.find('a.btn-trigger-revoke')['data-confirm']).to eq expected_alert
    end

    scenario 'revoke trigger' do
      # See if "Revoke" on trigger works post trigger creation
      page.accept_confirm do
        find('a.btn-trigger-revoke').send_keys(:return)
      end

      expect(page.find('.flash-notice')).to have_content 'Trigger removed'
      expect(page).to have_selector('p.settings-message.text-center.append-bottom-default')
    end
  end

  describe 'show triggers workflow' do
    scenario 'contains trigger description placeholder' do
      expect(page.find('#trigger_description')['placeholder']).to eq 'Trigger description'
    end

    scenario 'show "legacy" badge for legacy trigger' do
      create(:ci_trigger, owner: nil, project: @project)
      visit project_settings_ci_cd_path(@project)

      # See if trigger without owner (i.e. legacy) shows "legacy" badge and is editable
      expect(page.find('.triggers-list')).to have_content 'legacy'
      expect(page.find('.triggers-list')).to have_selector('a[title="Edit"]')
    end

    scenario 'show "invalid" badge for trigger with owner having insufficient permissions' do
      create(:ci_trigger, owner: guest_user, project: @project, description: trigger_title)
      visit project_settings_ci_cd_path(@project)

      # See if trigger without owner (i.e. legacy) shows "legacy" badge and is non-editable
      expect(page.find('.triggers-list')).to have_content 'invalid'
      expect(page.find('.triggers-list')).not_to have_selector('a[title="Edit"]')
    end

    scenario 'do not show "Edit" or full token for not owned trigger' do
      # Create trigger with user different from current_user
      create(:ci_trigger, owner: user2, project: @project, description: trigger_title)
      visit project_settings_ci_cd_path(@project)

      # See if trigger not owned by current_user shows only first few token chars and doesn't have copy-to-clipboard button
      expect(page.find('.triggers-list')).to have_content(@project.triggers.first.token[0..3])
      expect(page.find('.triggers-list')).not_to have_selector('button.btn-clipboard')

      # See if trigger owner name doesn't match with current_user and trigger is non-editable
      expect(page.find('.triggers-list .trigger-owner')).not_to have_content user.name
      expect(page.find('.triggers-list')).not_to have_selector('a[title="Edit"]')
    end

    scenario 'show "Edit" and full token for owned trigger' do
      create(:ci_trigger, owner: user, project: @project, description: trigger_title)
      visit project_settings_ci_cd_path(@project)

      # See if trigger shows full token and has copy-to-clipboard button
      expect(page.find('.triggers-list')).to have_content @project.triggers.first.token
      expect(page.find('.triggers-list')).to have_selector('button.btn-clipboard')

      # See if trigger owner name matches with current_user and is editable
      expect(page.find('.triggers-list .trigger-owner')).to have_content user.name
      expect(page.find('.triggers-list')).to have_selector('a[title="Edit"]')
    end
  end
end
