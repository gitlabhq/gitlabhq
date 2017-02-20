require 'spec_helper'

feature 'Project mirror', feature: true do
  let(:project) { create(:project, :mirror, :import_finished, creator: user, name: 'Victorialand') }
  let(:user) { create(:user) }

  describe 'On a project', js: true do
    before do
      project.team << [user, :master]
      login_as user
    end

    describe 'pressing "Update now"' do
      before { visit namespace_project_mirror_path(project.namespace, project) }

      it 'returns with the project updating (job enqueued)' do
        Sidekiq::Testing.fake! { click_link('Update Now') }

        expect(page).to have_content('Updating')
      end
    end

    describe 'synchronization times' do
      describe 'daily minimum mirror sync_time' do
        before do
          stub_application_setting(minimum_mirror_sync_time: Gitlab::Mirror::DAILY)
          visit namespace_project_mirror_path(project.namespace, project)
        end

        it 'shows the correct selector options' do
          expect(page).to have_selector('.project-mirror-sync-time > option', count: 1)
          expect(page).to have_selector('.remote-mirror-sync-time > option', count: 1)
        end
      end

      describe 'hourly minimum mirror sync_time' do
        before do
          stub_application_setting(minimum_mirror_sync_time: Gitlab::Mirror::HOURLY)
          visit namespace_project_mirror_path(project.namespace, project)
        end

        it 'shows the correct selector options' do
          expect(page).to have_selector('.project-mirror-sync-time > option', count: 2)
          expect(page).to have_selector('.remote-mirror-sync-time > option', count: 2)
        end
      end

      describe 'fifteen minimum mirror sync_time' do
        before do
          stub_application_setting(minimum_mirror_sync_time: Gitlab::Mirror::FIFTEEN)
          visit namespace_project_mirror_path(project.namespace, project)
        end

        it 'shows the correct selector options' do
          expect(page).to have_selector('.project-mirror-sync-time > option', count: 3)
          expect(page).to have_selector('.remote-mirror-sync-time > option', count: 3)
        end
      end
    end
  end
end
