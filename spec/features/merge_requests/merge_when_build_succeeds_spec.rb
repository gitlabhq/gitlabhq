require 'spec_helper'

feature 'Merge When Build Succeeds', feature: true, js: true do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public) }

  let(:merge_request) do
    create(:merge_request_with_diffs, source_project: project,
                                      author: user,
                                      title: 'Bug NS-04')
  end

  let(:pipeline) do
    create(:ci_pipeline, project: project,
                         sha: merge_request.diff_head_sha,
                         ref: merge_request.source_branch)
  end

  before { project.team << [user, :master] }

  context 'when there is active build for merge request' do
    background do
      create(:ci_build, pipeline: pipeline)
    end

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

  context 'when merge when build succeeds is enabled' do
    let(:merge_request) do
      create(:merge_request_with_diffs, :simple,  source_project: project,
                                                  author: user,
                                                  merge_user: user,
                                                  title: 'MepMep',
                                                  merge_when_build_succeeds: true)
    end

    let!(:build) do
      create(:ci_build, pipeline: pipeline)
    end

    before do
      login_as user
      visit_merge_request(merge_request)
    end

    it 'allows to cancel the automatic merge' do
      click_link "Cancel Automatic Merge"

      expect(page).to have_button "Merge When Build Succeeds"

      visit_merge_request(merge_request) # refresh the page
      expect(page).to have_content "Canceled the automatic merge"
    end

    it "allows the user to remove the source branch" do
      expect(page).to have_link "Remove Source Branch When Merged"

      click_link "Remove Source Branch When Merged"
      expect(page).to have_content "The source branch will be removed"
    end

    context 'when build succeeds' do
      background { build.success }

      it 'merges merge request' do
        visit_merge_request(merge_request) # refresh the page

        expect(page).to have_content 'The changes were merged'
        expect(merge_request.reload).to be_merged
      end
    end
  end

  context 'when build is not active' do
    it "does not allow to enable merge when build succeeds" do
      visit_merge_request(merge_request)
      expect(page).not_to have_link "Merge When Build Succeeds"
    end
  end

  context 'Has Environment' do
    let(:environment) { create(:environment, project: project) }
    
    it 'does show link to close the environment' do
        # TODO add test to verify if the button is visible when this condition
        # is met: if environment.closeable?
    end
  end
  
  def visit_merge_request(merge_request)
    visit namespace_project_merge_request_path(merge_request.project.namespace, merge_request.project, merge_request)
  end
end
