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
    before do
      ci_commit = create(:ci_commit, gl_project: project, sha: merge_request.last_commit.id, ref: merge_request.source_branch)
      ci_build = create(:ci_build, commit: ci_commit)

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

        expect(page).to have_content "Approved by #{user.name} to be merged automatically when the build succeeds."
        expect(page).to have_content "The source branch will not be removed."
      end
    end
  end

  context 'When it is enabled' do
    # No clue how, but push a new commit to the branch
    let(:merge_request) { create(:merge_request_with_diffs, source_project: project, # source_branch: "mepmep",
                                  author: user, title: "Bug NS-04", merge_when_build_succeeds: true) }

    before do
      merge_request.source_project.team << [user, :master]
      merge_request.source_branch = "feature"
      merge_request.target_branch = "master"
      merge_request.save!

      ci_commit = create(:ci_commit, gl_project: project, sha: merge_request.last_commit.id, ref: merge_request.source_branch)
      ci_build = create(:ci_build, commit: ci_commit)

      login_as user
      visit_merge_request(merge_request)
    end

    it 'cancels the automatic merge' do
      click_link "Cancel Automatic Merge"

      expect(page).to have_button  "Merge When Build Succeeds"
    end

    it "allows the user to remove the source branch" do
      expect(page).to have_link "Remove Source Branch When Merged"
    end
  end

  context 'Build is not active' do
    it "should not allow for enabling" do
      visit_merge_request(merge_request)
      expect(page).not_to have_button "Merge When Build Succeeds"
    end
  end

  def visit_merge_request(merge_request)
    visit namespace_project_merge_request_path(merge_request.project.namespace, merge_request.project, merge_request)
  end
end
