require 'spec_helper'

feature 'Project mirror', feature: true do
  let(:project) { create(:project, :mirror, :import_finished, creator: user, name: 'Victorialand') }
  let(:user) { create(:user) }

  describe 'On a project', js: true do
    before do
      project.team << [user, :master]
      sign_in user
    end

    context 'unlicensed' do
      before do
        stub_licensed_features(repository_mirrors: false)
      end

      it 'returns 404' do
        visit project_mirror_path(project)

        expect(page.status_code).to eq(404)
      end
    end

    context 'with Update now button' do
      let(:timestamp) { Time.now }

      before do
        project.mirror_data.update_attributes(next_execution_timestamp: timestamp + 10.minutes)
      end

      context 'when able to force update' do
        it 'forces import' do
          project.update_attributes(mirror_last_update_at: timestamp - 8.minutes)

          expect_any_instance_of(EE::Project).to receive(:force_import_job!)

          Timecop.freeze(timestamp) do
            visit project_mirror_path(project)
          end

          Sidekiq::Testing.fake! { click_link('Update Now') }
        end
      end

      context 'when unable to force update' do
        it 'does not force import' do
          project.update_attributes(mirror_last_update_at: timestamp - 3.minutes)

          expect_any_instance_of(EE::Project).not_to receive(:force_import_job!)

          Timecop.freeze(timestamp) do
            visit project_mirror_path(project)
          end

          expect(page).to have_content('Update Now')
          expect(page).to have_selector('.btn.disabled')
        end
      end
    end
  end
end
