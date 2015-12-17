require 'spec_helper'

feature 'Merge When Build Succeeds', feature: true, js: true do
  let(:user) { create(:user) }

  let(:project)       { create(:project, :public) }
  let(:merge_request) { create(:merge_request_with_diffs, source_project: project, author: user, title: "Bug NS-04") }

  before do
    project.team << [user, :master]
    project.enable_ci
  end

  context "Active build for Merge Request" do
    let!(:ci_commit) { create(:ci_commit, project: project, sha: merge_request.last_commit.id, ref: merge_request.source_branch) }
    let!(:ci_build) { create(:ci_build, commit: ci_commit) }

    before do
      login_as user
      visit_merge_request(merge_request)
    end

    it 'displays the Merge When Build Succeeds button' do
      expect(page).to have_button "Merge When Build Succeeds"
    end

    context "Merge When Build succeeds enabled" do
      before do
        click_button "Merge When Build Succeeds"
      end

      it 'activates Merge When Build Succeeds feature' do
        expect(page).to have_link "Cancel Automatic Merge"

        expect(page).to have_content "Set by #{user.name} to be merged automatically when the build succeeds."
        expect(page).to have_content "The source branch will not be removed."

        visit_merge_request(merge_request) # Needed to refresh the page
        expect(page).to have_content /Enabled an automatic merge when the build for [0-9a-f]{8} succeeds/i
      end
    end
  end

  context 'When it is enabled' do
    let(:merge_request) do
      create(:merge_request_with_diffs, :simple,  source_project: project, author: user,
                                                  merge_user: user, title: "MepMep", merge_when_build_succeeds: true)
    end

    let!(:ci_commit) { create(:ci_commit, project: project, sha: merge_request.last_commit.id, ref: merge_request.source_branch) }
    let!(:ci_build) { create(:ci_build, commit: ci_commit) }

    before do
      login_as user
      visit_merge_request(merge_request)
    end

    it 'cancels the automatic merge' do
      click_link "Cancel Automatic Merge"

      expect(page).to have_button "Merge When Build Succeeds"

      visit_merge_request(merge_request) # Needed to refresh the page
      expect(page).to have_content "Canceled the automatic merge"
    end

    it "allows the user to remove the source branch" do
      expect(page).to have_link "Remove Source Branch When Merged"

      click_link "Remove Source Branch When Merged"
      expect(page).to have_content "The source branch will be removed"
    end
  end

  context 'Build is not active' do
    it "should not allow for enabling" do
      visit_merge_request(merge_request)
      expect(page).not_to have_link "Merge When Build Succeeds"
    end
  end

  def visit_merge_request(merge_request)
    visit namespace_project_merge_request_path(merge_request.project.namespace, merge_request.project, merge_request)
  end
end
