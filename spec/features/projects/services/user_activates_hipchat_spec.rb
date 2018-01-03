require 'spec_helper'

describe 'User activates HipChat' do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    project.add_master(user)
    sign_in(user)

    visit(project_settings_integrations_path(project))

    click_link('HipChat')
  end

  context 'with standart settings' do
    it 'activates service' do
      check('Active')
      fill_in('Room', with: 'gitlab')
      fill_in('Token', with: 'verySecret')
      click_button('Save')

      expect(page).to have_content('HipChat activated.')
    end
  end

  context 'with custom settings' do
    it 'activates service' do
      check('Active')
      fill_in('Room', with: 'gitlab_custom')
      fill_in('Token', with: 'secretCustom')
      fill_in('Server', with: 'https://chat.example.com')
      click_button('Save')

      expect(page).to have_content('HipChat activated.')
    end
  end
end
