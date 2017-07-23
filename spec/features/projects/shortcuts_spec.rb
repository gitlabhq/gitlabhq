require 'spec_helper'

feature 'Project shortcuts', feature: true do
  let(:project) { create(:project, name: 'Victorialand') }
  let(:user) { create(:user) }

  describe 'On a project', js: true do
    before do
      project.team << [user, :master]
      sign_in user
      visit project_path(project)
    end

    describe 'pressing "i"' do
      it 'redirects to new issue page' do
        find('body').native.send_key('i')
        expect(page).to have_content('Victorialand')
      end
    end
  end
end
