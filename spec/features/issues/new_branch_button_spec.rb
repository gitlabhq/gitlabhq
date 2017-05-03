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

    it 'shows the new branch button', js: true do
      visit namespace_project_issue_path(project.namespace, project, issue)

      expect(page).to have_css('#new-branch .available')
    end

    context "when there is a referenced merge request" do
      let!(:note) do
        create(:note, :on_issue, :system, project: project, noteable: issue,
                                          note: "mentioned in #{referenced_mr.to_reference}")
      end

      let(:referenced_mr) do
        create(:merge_request, :simple, source_project: project, target_project: project,
                                        description: "Fixes #{issue.to_reference}", author: user)
      end

      before do
        referenced_mr.cache_merge_request_closes_issues!(user)

        visit namespace_project_issue_path(project.namespace, project, issue)
      end

      it "hides the new branch button", js: true do
        expect(page).to have_css('#new-branch .unavailable')
        expect(page).not_to have_css('#new-branch .available')
        expect(page).to have_content /1 Related Merge Request/
      end
    end
  end

  context "for visiters" do
    it 'shows no buttons', js: true do
      visit namespace_project_issue_path(project.namespace, project, issue)

      expect(page).not_to have_css('#new-branch')
    end
  end
end
