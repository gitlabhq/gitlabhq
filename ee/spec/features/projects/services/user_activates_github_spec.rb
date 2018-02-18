require 'spec_helper'

describe 'User activates GitHub Service' do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    project.add_master(user)
    sign_in(user)

    visit(project_settings_integrations_path(project))

    click_link('GitHub')
  end

  it 'activates service' do
    check('Active')
    fill_in "Token", with: "aaaaaaaaaa"
    fill_in "Api url", with: "https://api.github.com"
    fill_in "Owner", with: "h5bp"
    fill_in "Repository name", with: "html5-boilerplate"
    click_button('Save')

    expect(page).to have_content('GitHub activated.')
  end
end
