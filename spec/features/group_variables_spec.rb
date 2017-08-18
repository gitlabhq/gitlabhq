require 'spec_helper'

feature 'Group variables', js: true do
  let(:user) { create(:user) }
  let(:group) { create(:group) }

  background do
    group.add_master(user)
    gitlab_sign_in(user)
  end

  context 'when user creates a new variable' do
    background do
      visit group_settings_ci_cd_path(group)
      fill_in 'variable_key', with: 'AAA'
      fill_in 'variable_value', with: 'AAA123'
      find(:css, "#variable_protected").set(true)
      click_on 'Add new variable'
    end

    scenario 'user sees the created variable' do
      page.within('.variables-table') do
        expect(find(".variable-key")).to have_content('AAA')
        expect(find(".variable-value")).to have_content('******')
        expect(find(".variable-protected")).to have_content('Yes')
      end
      click_on 'Reveal Values'
      page.within('.variables-table') do
        expect(find(".variable-value")).to have_content('AAA123')
      end
    end
  end

  context 'when user edits a variable' do
    background do
      create(:ci_group_variable, key: 'AAA', value: 'AAA123', protected: true,
                                 group: group)

      visit group_settings_ci_cd_path(group)

      page.within('.variable-menu') do
        click_on 'Update'
      end

      fill_in 'variable_key', with: 'BBB'
      fill_in 'variable_value', with: 'BBB123'
      find(:css, "#variable_protected").set(false)
      click_on 'Save variable'
    end

    scenario 'user sees the updated variable' do
      page.within('.variables-table') do
        expect(find(".variable-key")).to have_content('BBB')
        expect(find(".variable-value")).to have_content('******')
        expect(find(".variable-protected")).to have_content('No')
      end
    end
  end

  context 'when user deletes a variable' do
    background do
      create(:ci_group_variable, key: 'BBB', value: 'BBB123', protected: false,
                                 group: group)

      visit group_settings_ci_cd_path(group)

      page.within('.variable-menu') do
        page.accept_alert 'Are you sure?' do
          click_on 'Remove'
        end
      end
    end

    scenario 'user does not see the deleted variable' do
      expect(page).to have_no_css('.variables-table')
    end
  end
end
