require 'spec_helper'

describe 'Projects > Show > User interacts with project stars' do
  let(:project) { create(:project, :public, :repository) }

  context 'when user is signed in', :js do
    let(:user) { create(:user) }

    before do
      sign_in(user)
      visit(project_path(project))
    end

    it 'toggles the star' do
      find('.star-btn').click

      expect(page).to have_css('.star-count', text: 1)

      find('.star-btn').click

      expect(page).to have_css('.star-count', text: 0)
    end
  end

  context 'when user is not signed in' do
    before do
      visit(project_path(project))
    end

    it 'does not allow to star a project' do
      expect(page).not_to have_content('.toggle-star')

      find('.star-btn').click

      expect(current_path).to eq(new_user_session_path)
    end
  end
end
