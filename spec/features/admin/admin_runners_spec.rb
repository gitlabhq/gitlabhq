require 'spec_helper'

describe "Admin Runners" do
  include StubENV

  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
    sign_in(create(:admin))
  end

  describe "Runners page" do
    let(:pipeline) { create(:ci_pipeline) }

    context "when there are runners" do
      before do
        runner = FactoryGirl.create(:ci_runner, contacted_at: Time.now)
        FactoryGirl.create(:ci_build, pipeline: pipeline, runner_id: runner.id)
        visit admin_runners_path
      end

      it 'has all necessary texts' do
        expect(page).to have_text "How to setup"
        expect(page).to have_text "Runners with last contact more than a minute ago: 1"
      end

      describe 'search' do
        before do
          FactoryGirl.create :ci_runner, description: 'runner-foo'
          FactoryGirl.create :ci_runner, description: 'runner-bar'
        end

        it 'shows correct runner when description matches' do
          search_form = find('#runners-search')
          search_form.fill_in 'search', with: 'runner-foo'
          search_form.click_button 'Search'

          expect(page).to have_content("runner-foo")
          expect(page).not_to have_content("runner-bar")
        end

        it 'shows no runner when description does not match' do
          search_form = find('#runners-search')
          search_form.fill_in 'search', with: 'runner-baz'
          search_form.click_button 'Search'

          expect(page).to have_text 'No runners found'
        end
      end
    end

    context "when there are no runners" do
      before do
        visit admin_runners_path
      end

      it 'has all necessary texts including no runner message' do
        expect(page).to have_text "How to setup"
        expect(page).to have_text "Runners with last contact more than a minute ago: 0"
        expect(page).to have_text 'No runners found'
      end
    end
  end

  describe "Runner show page" do
    let(:runner) { FactoryGirl.create :ci_runner }

    before do
      @project1 = FactoryGirl.create(:empty_project)
      @project2 = FactoryGirl.create(:empty_project)
      visit admin_runner_path(runner)
    end

    describe 'runner info' do
      it { expect(find_field('runner_token').value).to eq runner.token }
    end

    describe 'projects' do
      it 'contains project names' do
        expect(page).to have_content(@project1.name_with_namespace)
        expect(page).to have_content(@project2.name_with_namespace)
      end
    end

    describe 'search' do
      before do
        search_form = find('#runner-projects-search')
        search_form.fill_in 'search', with: @project1.name
        search_form.click_button 'Search'
      end

      it 'contains name of correct project' do
        expect(page).to have_content(@project1.name_with_namespace)
        expect(page).not_to have_content(@project2.name_with_namespace)
      end
    end

    describe 'enable/create' do
      shared_examples 'assignable runner' do
        it 'enables a runner for a project' do
          within '.unassigned-projects' do
            click_on 'Enable'
          end

          assigned_project = page.find('.assigned-projects')

          expect(assigned_project).to have_content(@project2.path)
        end
      end

      context 'with specific runner' do
        before do
          @project1.runners << runner
          visit admin_runner_path(runner)
        end

        it_behaves_like 'assignable runner'
      end

      context 'with locked runner' do
        before do
          runner.update(locked: true)
          @project1.runners << runner
          visit admin_runner_path(runner)
        end

        it_behaves_like 'assignable runner'
      end

      context 'with shared runner' do
        before do
          @project1.destroy
          runner.update(is_shared: true)
          visit admin_runner_path(runner)
        end

        it_behaves_like 'assignable runner'
      end
    end

    describe 'disable/destroy' do
      before do
        @project1.runners << runner
        visit admin_runner_path(runner)
      end

      it 'enables specific runner for project' do
        within '.assigned-projects' do
          click_on 'Disable'
        end

        new_runner_project = page.find('.unassigned-projects')

        expect(new_runner_project).to have_content(@project1.path)
      end
    end
  end

  describe 'runners registration token' do
    let!(:token) { current_application_settings.runners_registration_token }

    before do
      visit admin_runners_path
    end

    it 'has a registration token' do
      expect(page.find('#registration_token')).to have_content(token)
    end

    describe 'reload registration token' do
      let(:page_token) { find('#registration_token').text }

      before do
        click_button 'Reset runners registration token'
      end

      it 'changes registration token' do
        expect(page_token).not_to eq token
      end
    end
  end
end
