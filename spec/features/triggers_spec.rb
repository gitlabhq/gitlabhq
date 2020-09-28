# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Triggers', :js do
  let(:trigger_title) { 'trigger desc' }
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:guest_user) { create(:user) }

  before do
    sign_in(user)

    @project = create(:project)
    @project.add_maintainer(user)
    @project.add_maintainer(user2)
    @project.add_guest(guest_user)

    visit project_settings_ci_cd_path(@project)
  end

  shared_examples 'triggers page' do
    describe 'create trigger workflow' do
      it 'prevents adding new trigger with no description' do
        fill_in 'trigger_description', with: ''
        click_button 'Add trigger'

        # See if input has error due to empty value
        expect(page.find('form.gl-show-field-errors .gl-field-error')).to be_visible
      end

      it 'adds new trigger with description' do
        fill_in 'trigger_description', with: 'trigger desc'
        click_button 'Add trigger'

        aggregate_failures 'display creation notice and trigger is created' do
          expect(page.find('.flash-notice')).to have_content 'Trigger was created successfully.'
          expect(page.find('.triggers-list')).to have_content 'trigger desc'
          expect(page.find('.triggers-list .trigger-owner')).to have_content user.name
        end
      end
    end

    describe 'edit trigger workflow' do
      let(:new_trigger_title) { 'new trigger' }

      it 'click on edit trigger opens edit trigger page' do
        create(:ci_trigger, owner: user, project: @project, description: trigger_title)
        visit project_settings_ci_cd_path(@project)

        # See if edit page has correct descrption
        find('a[title="Edit"]').send_keys(:return)
        expect(page.find('#trigger_description').value).to have_content 'trigger desc'
      end

      it 'edit trigger and save' do
        create(:ci_trigger, owner: user, project: @project, description: trigger_title)
        visit project_settings_ci_cd_path(@project)

        # See if edit page opens, then fill in new description and save
        find('a[title="Edit"]').send_keys(:return)
        fill_in 'trigger_description', with: new_trigger_title
        click_button 'Save trigger'

        aggregate_failures 'display update notice and trigger is updated' do
          expect(page.find('.flash-notice')).to have_content 'Trigger was successfully updated.'
          expect(page.find('.triggers-list')).to have_content new_trigger_title
          expect(page.find('.triggers-list .trigger-owner')).to have_content user.name
        end
      end
    end

    describe 'trigger "Revoke" workflow' do
      before do
        create(:ci_trigger, owner: user2, project: @project, description: trigger_title)
        visit project_settings_ci_cd_path(@project)
      end

      it 'button "Revoke" has correct alert' do
        expected_alert = 'By revoking a trigger you will break any processes making use of it. Are you sure?'
        expect(page.find('[data-testid="trigger_revoke_button"]')['data-confirm']).to eq expected_alert
      end

      it 'revoke trigger' do
        # See if "Revoke" on trigger works post trigger creation
        page.accept_confirm do
          find('[data-testid="trigger_revoke_button"]').send_keys(:return)
        end

        aggregate_failures 'trigger is removed' do
          expect(page.find('.flash-notice')).to have_content 'Trigger removed'
          expect(page).to have_css('[data-testid="no_triggers_content"]')
        end
      end
    end

    describe 'show triggers workflow' do
      it 'contains trigger description placeholder' do
        expect(page.find('#trigger_description')['placeholder']).to eq 'Trigger description'
      end

      it 'show "invalid" badge for trigger with owner having insufficient permissions' do
        create(:ci_trigger, owner: guest_user, project: @project, description: trigger_title)
        visit project_settings_ci_cd_path(@project)

        aggregate_failures 'has invalid badge and no edit link' do
          expect(page.find('.triggers-list')).to have_content 'invalid'
          expect(page.find('.triggers-list')).not_to have_selector('a[title="Edit"]')
        end
      end

      it 'do not show "Edit" or full token for not owned trigger' do
        # Create trigger with user different from current_user
        create(:ci_trigger, owner: user2, project: @project, description: trigger_title)
        visit project_settings_ci_cd_path(@project)

        aggregate_failures 'shows truncated token, no clipboard button and no edit link' do
          expect(page.find('.triggers-list')).to have_content(@project.triggers.first.token[0..3])
          expect(page.find('.triggers-list')).not_to have_selector('[data-testid="clipboard-btn"]')
          expect(page.find('.triggers-list .trigger-owner')).not_to have_content user.name
          expect(page.find('.triggers-list')).not_to have_selector('a[title="Edit"]')
        end
      end

      it 'show "Edit" and full token for owned trigger' do
        create(:ci_trigger, owner: user, project: @project, description: trigger_title)
        visit project_settings_ci_cd_path(@project)

        aggregate_failures 'shows full token, clipboard button and edit link' do
          expect(page.find('.triggers-list')).to have_content @project.triggers.first.token
          expect(page.find('.triggers-list')).to have_selector('[data-testid="clipboard-btn"]')
          expect(page.find('.triggers-list .trigger-owner')).to have_content user.name
          expect(page.find('.triggers-list')).to have_selector('a[title="Edit"]')
        end
      end
    end
  end

  context 'when ci_pipeline_triggers_settings_vue_ui is enabled' do
    it_behaves_like 'triggers page'
  end

  context 'when ci_pipeline_triggers_settings_vue_ui is disabled' do
    before do
      stub_feature_flags(ci_pipeline_triggers_settings_vue_ui: false)
    end

    it_behaves_like 'triggers page'
  end
end
