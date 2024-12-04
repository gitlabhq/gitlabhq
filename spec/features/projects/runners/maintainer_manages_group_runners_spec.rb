# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Maintainer manages group runners related to project', feature_category: :fleet_visibility do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create :project, group: group }

  before_all do
    project.add_maintainer(user)
  end

  before do
    sign_in(user)
  end

  describe 'group runners in project settings' do
    context 'as project and group maintainer' do
      before_all do
        group.add_maintainer(user)
      end

      it 'group runners are not available' do
        visit project_runners_path(project)

        expect(page).not_to have_content 'To register them, go to the group\'s Runners page.'
        expect(page).to have_content 'Ask your group owner to set up a group runner'
      end
    end

    context 'as project maintainer and group owner' do
      before_all do
        group.add_owner(user)
      end

      it 'group runners are available' do
        visit project_runners_path(project)

        expect(page).to have_content 'This group does not have any group runners yet.'

        expect(page).to have_content 'To register them, go to the group\'s Runners page.'
        expect(page).not_to have_content 'Ask your group owner to set up a group runner'
      end
    end

    context 'as project maintainer' do
      context 'with group project' do
        context 'with a project with no group runners' do
          it 'group runners are not available' do
            visit project_runners_path(project)

            expect(page).to have_content 'This group does not have any group runners yet.'

            expect(page).not_to have_content 'To register them, go to the group\'s Runners page.'
            expect(page).to have_content 'Ask your group owner to set up a group runner.'
          end
        end

        context 'with a project and a group runner' do
          let_it_be(:group_runner) do
            create(:ci_runner, :group, groups: [group], description: 'group-runner')
          end

          it 'group runners are available' do
            visit project_runners_path(project)

            expect(page).to have_content 'Available group runners: 1'
            expect(page).to have_content 'group-runner'
          end

          it 'group runners may be disabled for a project' do
            visit project_runners_path(project)

            click_on 'Disable group runners'

            expect(page).to have_content 'Enable group runners'
            expect(project.reload.group_runners_enabled).to be false

            click_on 'Enable group runners'

            expect(page).to have_content 'Disable group runners'
            expect(project.reload.group_runners_enabled).to be true
          end

          context 'when multiple group runners are configured' do
            let_it_be(:group_runner_2) { create(:ci_runner, :group, groups: [group]) }

            it 'shows the runner count' do
              visit project_runners_path(project)

              within_testid 'group-runners' do
                expect(page).to have_content format(_('Available group runners: %{runners}'), { runners: 2 })
              end
            end

            it 'adds pagination to the group runner list' do
              stub_const('Projects::Settings::CiCdController::NUMBER_OF_RUNNERS_PER_PAGE', 1)

              visit project_runners_path(project)

              within_testid 'group-runners' do
                expect(find('.gl-pagination')).not_to be_nil
              end
            end
          end
        end
      end
    end
  end
end
