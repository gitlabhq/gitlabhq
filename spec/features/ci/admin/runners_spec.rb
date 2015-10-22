require 'spec_helper'

describe "Admin Runners" do
  before do
    login_as :admin
  end

  describe "Runners page" do
    before do
      runner = FactoryGirl.create(:ci_runner)
      commit = FactoryGirl.create(:ci_commit)
      FactoryGirl.create(:ci_build, commit: commit, runner_id: runner.id)
      visit ci_admin_runners_path
    end

    it { page.has_text? "Manage Runners" }
    it { page.has_text? "To register a new runner" }
    it { page.has_text? "Runners with last contact less than a minute ago: 1" }

    describe 'search' do
      before do
        FactoryGirl.create :ci_runner, description: 'runner-foo'
        FactoryGirl.create :ci_runner, description: 'runner-bar'

        search_form = find('#runners-search')
        search_form.fill_in 'search', with: 'runner-foo'
        search_form.click_button 'Search'
      end

      it { expect(page).to have_content("runner-foo") }
      it { expect(page).not_to have_content("runner-bar") }
    end
  end

  describe "Runner show page" do
    let(:runner) { FactoryGirl.create :ci_runner }

    before do
      @project1 = FactoryGirl.create(:ci_project)
      @project2 = FactoryGirl.create(:ci_project)
      visit ci_admin_runner_path(runner)
    end

    describe 'runner info' do
      it { expect(find_field('runner_token').value).to eq runner.token }
    end

    describe 'projects' do
      it { expect(page).to have_content(@project1.name_with_namespace) }
      it { expect(page).to have_content(@project2.name_with_namespace) }
    end

    describe 'search' do
      before do
        search_form = find('#runner-projects-search')
        search_form.fill_in 'search', with: @project1.gl_project.name
        search_form.click_button 'Search'
      end

      it { expect(page).to have_content(@project1.name_with_namespace) }
      it { expect(page).not_to have_content(@project2.name_with_namespace) }
    end
  end
end
