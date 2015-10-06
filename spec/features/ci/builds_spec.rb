require 'spec_helper'

describe "Builds" do
  context :private_project do
    before do
      @commit = FactoryGirl.create :ci_commit
      @build = FactoryGirl.create :ci_build, commit: @commit
      login_as :user
      @commit.project.gl_project.team << [@user, :master]
    end

    describe "GET /:project/builds/:id/cancel" do
      before do
        @build.run!
        visit cancel_ci_project_build_path(@commit.project, @build)
      end

      it { expect(page).to have_content 'canceled' }
      it { expect(page).to have_content 'Retry' }
    end

    describe "POST /:project/builds/:id/retry" do
      before do
        @build.cancel!
        visit ci_project_build_path(@commit.project, @build)
        click_link 'Retry'
      end

      it { expect(page).to have_content 'pending' }
      it { expect(page).to have_content 'Cancel' }
    end
  end
end
