# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group > Settings > Fine-grained personal access token enforcement',
  :js, feature_category: :system_access do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, owners: user) }

  let(:selected_group) { group }

  let(:checkbox_label) do
    s_('AccessTokens|Require fine-grained personal access tokens after a specific date')
  end

  subject(:visit_page) { visit edit_group_path(selected_group, anchor: 'js-permissions-settings') }

  before do
    sign_in(user)
  end

  context 'when `granular_personal_access_tokens_enforcement_saas` feature flag is disabled' do
    before do
      stub_feature_flags(granular_personal_access_tokens_enforcement_saas: false)
    end

    it 'does not show the enforcement section' do
      visit_page

      expect(page).not_to have_content(s_('AccessTokens|Fine-grained personal access tokens'))
    end
  end

  context 'when `granular_personal_access_tokens_enforcement_saas` feature flag is enabled' do
    context 'when group is a subgroup' do
      let_it_be(:subgroup) { create(:group, parent: group, owners: user) }

      let(:selected_group) { subgroup }

      it 'does not show the enforcement section' do
        visit_page

        expect(page).not_to have_content(s_('AccessTokens|Fine-grained personal access tokens'))
      end
    end

    context 'when group is a root group' do
      it 'shows the enforcement section' do
        visit_page

        expect(page).to have_content(s_('AccessTokens|Fine-grained personal access tokens'))
      end

      it 'persists the enforcement settings when checked with a valid date' do
        visit_page

        check checkbox_label
        fill_in 'group_granular_tokens_enforced_after', with: Date.current.to_s

        click_button 'Save changes'

        expect(page).to have_content("Group '#{group.name}' was successfully updated.")
        expect(group.namespace_settings.reload.enforce_granular_tokens).to be(true)
        expect(group.namespace_settings.granular_tokens_enforced_after).to eq(Date.current)
      end

      it 'shows an inline validation error when checkbox is checked but date is cleared' do
        visit_page

        check checkbox_label
        fill_in 'group_granular_tokens_enforced_after', with: ''

        expect(page).to have_content(_('Please enter a date value.'))
      end

      context 'when enforcement is already enabled' do
        before do
          group.namespace_settings.update_columns(
            personal_access_token_settings: {
              enforce_granular_tokens: true,
              granular_tokens_enforced_after: 1.month.ago.to_date
            }
          )
        end

        it 'pre-checks the checkbox and pre-fills the date' do
          visit_page

          expect(page).to have_checked_field(checkbox_label)
          expect(page).to have_field(
            'group_granular_tokens_enforced_after',
            with: 1.month.ago.to_date.to_s
          )
        end

        it 'saving without changing the date does not raise a validation error' do
          visit_page

          click_button 'Save changes'

          expect(page).to have_content("Group '#{group.name}' was successfully updated.")
        end

        it 'unchecking the checkbox disables enforcement and clears the date' do
          visit_page

          uncheck checkbox_label
          click_button 'Save changes'

          expect(page).to have_content("Group '#{group.name}' was successfully updated.")
          expect(group.namespace_settings.reload.enforce_granular_tokens).to be(false)
          expect(group.namespace_settings.granular_tokens_enforced_after).to be_nil
        end
      end
    end
  end
end
