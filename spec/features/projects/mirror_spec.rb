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
      Gitlab::Mirror::SYNC_TIME_TO_CRON.keys.reverse.each_with_index do |sync_time, index|
        describe "#{sync_time} minimum mirror sync time" do
          before do
            stub_application_setting(minimum_mirror_sync_time: sync_time)
            visit namespace_project_mirror_path(project.namespace, project)
          end

          it 'shows the correct selector options' do
            expect(page).to have_selector('.project-mirror-sync-time > option', count: index + 1)
          end
        end
      end
    end
  end
end
