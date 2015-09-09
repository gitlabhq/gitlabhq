require 'spec_helper'

describe "Admin Runners" do
  before do
    skip_admin_auth
    login_as :user
  end

  describe "Runners page" do
    before do
      runner = FactoryGirl.create(:runner)
      commit = FactoryGirl.create(:commit)
      FactoryGirl.create(:build, commit: commit, runner_id: runner.id)
      visit admin_runners_path
    end

    it { page.has_text? "Manage Runners" }
    it { page.has_text? "To register a new runner" }
    it { page.has_text? "Runners with last contact less than a minute ago: 1" }

    describe 'search' do
      before do
        FactoryGirl.create :runner, description: 'foo'
        FactoryGirl.create :runner, description: 'bar'

        fill_in 'search', with: 'foo'
        click_button 'Search'
      end

      it { page.should have_content("foo") }
      it { page.should_not have_content("bar") }
    end
  end

  describe "Runner show page" do
    let(:runner) { FactoryGirl.create :runner }

    before do
      FactoryGirl.create(:project, name: "foo")
      FactoryGirl.create(:project, name: "bar")
      visit admin_runner_path(runner)
    end

    describe 'runner info' do
      it { find_field('runner_token').value.should eq runner.token }
    end

    describe 'projects' do
      it { page.should have_content("foo") }
      it { page.should have_content("bar") }
    end

    describe 'search' do
      before do
        fill_in 'search', with: 'foo'
        click_button 'Search'
      end

      it { page.should have_content("foo") }
      it { page.should_not have_content("bar") }
    end
  end
end
