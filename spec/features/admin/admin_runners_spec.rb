require 'spec_helper'

describe "Admin Runners" do
  before do
    login_as :admin
  end

  describe "Runners page" do
    before do
      runner = FactoryGirl.create(:ci_runner, contacted_at: Time.now)
      pipeline = FactoryGirl.create(:ci_pipeline)
      FactoryGirl.create(:ci_build, pipeline: pipeline, runner_id: runner.id)
      visit admin_runners_path
    end

    it 'has all necessary texts' do
      expect(page).to have_text "To register a new Runner"
      expect(page).to have_text "Runners with last contact less than a minute ago: 1"
    end

    describe 'search' do
      before do
        FactoryGirl.create :ci_runner, description: 'runner-foo'
        FactoryGirl.create :ci_runner, description: 'runner-bar'

        search_form = find('#runners-search')
        search_form.fill_in 'search', with: 'runner-foo'
        search_form.click_button 'Search'
      end

      it 'shows correct runner' do
        expect(page).to have_content("runner-foo")
        expect(page).not_to have_content("runner-bar")
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
    before { visit admin_runners_path }

    it 'has a registration token' do
      expect(page).to have_content("Registration token is #{token}")
      expect(page).to have_selector('#runners-token', text: token)
    end

    describe 'reload registration token' do
      let(:page_token) { find('#runners-token').text }

      before do
        click_button 'Reset runners registration token'
      end

      it 'changes registration token' do
        expect(page_token).not_to eq token
      end
    end
  end
end
