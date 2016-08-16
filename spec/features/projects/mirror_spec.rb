require 'spec_helper'

feature 'Project mirror', feature: true do
  let(:project) { create(:project, :mirror, :import_finished, creator: user, name: 'Victorialand') }
  let(:user) { create(:user) }

  describe 'On a project', js: true do
    before do
      project.team << [user, :master]
      login_as user
      visit namespace_project_mirror_path(project.namespace, project)
    end

    describe 'pressing "Update now"' do
      it 'returns with the project updating (job enqueued)' do
        Sidekiq::Testing.fake! { click_link('Update Now') }

        expect(page).to have_content('Updating')
      end
    end
  end
end
