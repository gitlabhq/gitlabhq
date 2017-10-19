require 'spec_helper'

feature 'Projects > Push Rules', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository, namespace: user.namespace) }

  before do
    project.team << [user, :master]
    sign_in(user)
  end

  describe 'Reject unsigned commits rule' do
    context 'unlicensed' do
      before do
        stub_licensed_features(reject_unsigned_commits: false)
      end

      it 'does not render the setting checkbox' do
        visit project_settings_repository_path(project)

        expect(page).not_to have_content('Reject unsigned commits')
      end
    end

    context 'licensed' do
      let(:bronze_plan) { Plan.find_by!(name: 'bronze') }
      let(:gold_plan) { Plan.find_by!(name: 'gold') }

      before do
        stub_licensed_features(reject_unsigned_commits: true)
      end

      it 'renders the setting checkbox' do
        visit project_settings_repository_path(project)

        expect(page).to have_content('Reject unsigned commits')
      end

      describe 'with GL.com plans' do
        before do
          stub_application_setting(check_namespace_plan: true)
        end

        context 'when disabled' do
          it 'does not render the setting checkbox' do
            project.namespace.update!(plan_id: bronze_plan.id)

            visit project_settings_repository_path(project)

            expect(page).not_to have_content('Reject unsigned commits')
          end
        end

        context 'when enabled' do
          it 'renders the setting checkbox' do
            project.namespace.update!(plan_id: gold_plan.id)

            visit project_settings_repository_path(project)

            expect(page).to have_content('Reject unsigned commits')
          end
        end
      end
    end
  end
end
