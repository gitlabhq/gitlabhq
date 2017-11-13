require 'spec_helper'

describe 'User activates Emails on push' do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    project.add_master(user)
    sign_in(user)

    visit(project_settings_integrations_path(project))

    click_link('Emails on push')
  end

  it 'activates service' do
    check('Active')
    fill_in('Recipients', with: 'qa@company.name')
    click_button('Save')

    expect(page).to have_content('Emails on push activated.')
  end
end
