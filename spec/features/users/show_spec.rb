require 'spec_helper'

describe 'User page' do
  let(:user) { create(:user) }

  it 'shows all the tabs' do
    visit(user_path(user))

    page.within '.nav-links' do
      expect(page).to have_link('Activity')
      expect(page).to have_link('Groups')
      expect(page).to have_link('Contributed projects')
      expect(page).to have_link('Personal projects')
      expect(page).to have_link('Snippets')
    end
  end
end
