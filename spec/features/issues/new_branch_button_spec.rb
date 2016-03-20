require 'rails_helper'

feature 'Start new branch from an issue', feature: true do
  let!(:project)   { create(:project) }
  let!(:issue)     { create(:issue, project: project) }
  let!(:user)      { create(:user)}

  context "for team members" do
    before do
      project.team << [user, :master]
      login_as(user)
    end

    it 'shown the new branch button', js: false do
      visit namespace_project_issue_path(project.namespace, project, issue)

      expect(page).to have_link "New Branch"
    end

    context "when there is a referenced merge request" do
      let(:note) do
        create(:note, :on_issue, :system, project: project,
                                          note: "mentioned in !#{referenced_mr.iid}")
      end
      let(:referenced_mr) do
        create(:merge_request, :simple, source_project: project, target_project: project,
                                        description: "Fixes ##{issue.iid}", author: user)
      end

      before do
        issue.notes << note

        visit namespace_project_issue_path(project.namespace, project, issue)
      end

      it "hides the new branch button", js: true do
        expect(page).not_to have_link "New Branch"
        expect(page).to have_content /1 Related Merge Request/
      end
    end
  end

  context "for visiters" do
    it 'no button is shown', js: false do
      visit namespace_project_issue_path(project.namespace, project, issue)
      expect(page).not_to have_link "New Branch"
    end
  end
end
