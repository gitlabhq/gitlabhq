# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Triggers', :js, feature_category: :continuous_integration do
  include Spec::Support::Helpers::ModalHelpers

  let(:trigger_title) { 'trigger desc' }
  let_it_be(:user) { create(:user) }
  let_it_be(:user2) { create(:user) }
  let_it_be(:guest_user) { create(:user) }
  let_it_be(:project) { create(:project) }

  before_all do
    project.add_maintainer(user)
    project.add_maintainer(user2)
    project.add_guest(guest_user)
  end

  describe 'triggers page' do
    describe 'create trigger workflow' do
      before do
        sign_in(user)

        visit project_settings_ci_cd_path(project)

        wait_for_requests
      end

      it 'prevents adding new trigger with no description' do
        click_button 'Add new token'
        fill_in 'trigger_description', with: ''
        click_button 'Create pipeline trigger token'

        # See if input has error due to empty value
        expect(page.find('form.gl-show-field-errors .gl-field-error')).to be_visible
      end

      it 'adds new trigger with description' do
        click_button 'Add new token'
        fill_in 'trigger_description', with: 'trigger desc'
        click_button 'Create pipeline trigger token'

        aggregate_failures 'display creation notice and trigger is created' do
          expect(find_by_testid('alert-info')).to have_content 'Trigger token was created successfully.'
          expect(page.find('.triggers-list')).to have_content 'trigger desc'
          expect(page.find('.triggers-list .trigger-owner')).to have_content user.name
        end
      end

      context 'when trigger is not saved' do
        before do
          allow_next_instance_of(Ci::PipelineTriggers::CreateService) do |instance|
            allow(instance).to receive(:execute).and_return(
              ServiceResponse.error(
                message: 'Validation error',
                payload: { trigger: { description: ['is missing'] } },
                reason: :validation_error
              )
            )
          end
        end

        it 'trigger.errors has an error' do
          click_button 'Add new token'
          fill_in 'trigger_description', with: 'trigger desc'
          click_button 'Create pipeline trigger token'

          expect(page.find('.flash-container')).to(
            have_content("Validation error")
          )
        end
      end
    end

    describe 'edit trigger workflow' do
      let(:new_trigger_title) { 'new trigger' }

      before do
        create(:ci_trigger, owner: user, project: project, description: trigger_title)

        sign_in(user)

        visit project_settings_ci_cd_path(project)

        wait_for_requests
      end

      it 'click on edit trigger opens edit trigger modal' do
        # See if edit modal has correct descrption
        find('button[title="Edit"]').send_keys(:return)
        page.within('[id="edit-trigger-modal"]') do
          expect(page.find('#edit_trigger_description').value).to have_content 'trigger desc'
        end
      end

      it 'edit trigger and save' do
        # See if edit modal opens, then fill in new description and save
        find('button[title="Edit"]').send_keys(:return)
        page.within('[id="edit-trigger-modal"]') do
          fill_in 'edit_trigger_description', with: new_trigger_title
          click_button 'Update'
        end

        aggregate_failures 'display update notice and trigger is updated' do
          expect(page.find('.triggers-list')).to have_content new_trigger_title
          expect(page.find('.triggers-list .trigger-owner')).to have_content user.name
        end
      end
    end

    describe 'trigger "Revoke" workflow' do
      before do
        create(:ci_trigger, owner: user2, project: project, description: trigger_title)

        sign_in(user)

        visit project_settings_ci_cd_path(project)

        wait_for_requests
      end

      it 'button "Revoke" has correct alert' do
        expected_alert = 'By revoking a trigger token you will break any processes making use of it. Are you sure?'
        expect(find_by_testid('trigger_revoke_button')['data-confirm']).to eq expected_alert
      end

      it 'revoke trigger' do
        # See if "Revoke" on trigger works post trigger creation
        accept_gl_confirm(button_text: 'Revoke') do
          find_by_testid('trigger_revoke_button').send_keys(:return)
        end

        aggregate_failures 'trigger is removed' do
          expect(find_by_testid('alert-info')).to have_content 'Trigger token removed'
          expect(page).to have_css('[data-testid="no_triggers_content"]')
        end
      end

      context 'when an error occurs' do
        before do
          allow_next_instance_of(Ci::PipelineTriggers::DestroyService) do |instance|
            allow(instance).to receive(:execute).and_return(
              ServiceResponse.error(
                message: 'An error occurred',
                reason: :validation_error
              )
            )
          end

          accept_gl_confirm(button_text: 'Revoke') do
            find_by_testid('trigger_revoke_button').send_keys(:return)
          end
        end

        it 'flashes an error' do
          expect(page.find('.flash-container')).to(
            have_content("An error occurred")
          )
        end
      end
    end

    describe 'show triggers workflow' do
      before do
        sign_in(user)
      end

      it 'contains trigger description placeholder' do
        visit project_settings_ci_cd_path(project)

        wait_for_requests

        click_button 'Add new token'
        expect(page.find('#trigger_description')['placeholder']).to eq 'Trigger description'
      end

      it 'show "invalid" badge for trigger with owner having insufficient permissions' do
        create(:ci_trigger, owner: guest_user, project: project, description: trigger_title)
        visit project_settings_ci_cd_path(project)

        aggregate_failures 'has invalid badge and no edit link' do
          expect(page.find('.triggers-list')).to have_content 'invalid'
          expect(page.find('.triggers-list')).not_to have_selector('a[title="Edit"]')
        end
      end

      it 'hides the token value and reveals when clicking the "reveal values" button', :aggregate_failures do
        create(:ci_trigger, owner: user, project: project, description: trigger_title)
        visit project_settings_ci_cd_path(project)

        expect(page.find('.triggers-list')).to have_content('*' * 47)

        find_by_testid('reveal-hide-values-button').click

        expect(page.find('.triggers-list')).to have_content(project.triggers.first.token)
      end

      it 'do not show "Edit" or full token for not owned trigger' do
        # Create trigger with user different from current_user
        create(:ci_trigger, owner: user2, project: project, description: trigger_title)
        visit project_settings_ci_cd_path(project)

        find_by_testid('reveal-hide-values-button').click

        aggregate_failures 'shows truncated token, no clipboard button and no edit link' do
          expect(page.find('.triggers-list')).to have_content(project.triggers.first.short_token)
          expect(page.find('.triggers-list')).not_to have_selector('[data-testid="clipboard-btn"]')
          expect(page.find('.triggers-list .trigger-owner')).not_to have_content user.name
          expect(page.find('.triggers-list')).not_to have_selector('a[title="Edit"]')
        end
      end

      it 'show "Edit" and full token for owned trigger' do
        create(:ci_trigger, owner: user, project: project, description: trigger_title)
        visit project_settings_ci_cd_path(project)

        find_by_testid('reveal-hide-values-button').click

        aggregate_failures 'shows full token, clipboard button and edit link' do
          expect(page.find('.triggers-list')).to have_content project.triggers.first.token
          expect(page.find('.triggers-list')).to have_selector('[data-testid="clipboard-btn"]')
          expect(page.find('.triggers-list .trigger-owner')).to have_content user.name
          expect(page.find('.triggers-list')).to have_selector('button[title="Edit"]')
        end
      end
    end
  end
end
