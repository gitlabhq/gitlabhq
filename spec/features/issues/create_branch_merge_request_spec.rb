require 'rails_helper'

feature 'Create Branch/Merge Request Dropdown on issue page', feature: true, js: true do
  let(:user) { create(:user) }
  let!(:project) { create(:project) }
  let(:issue) { create(:issue, project: project, title: 'Cherry-Coloured Funk') }

  context 'for team members' do
    before do
      project.team << [user, :developer]
      sign_in(user)
    end

    it 'allows creating a merge request from the issue page' do
      visit project_issue_path(project, issue)

      select_dropdown_option('create-mr')

      wait_for_requests

      expect(page).to have_content("created branch 1-cherry-coloured-funk")
      expect(page).to have_content("mentioned in merge request !1")

      visit project_merge_request_path(project, MergeRequest.first)

      expect(page).to have_content('WIP: Resolve "Cherry-Coloured Funk"')
      expect(current_path).to eq(project_merge_request_path(project, MergeRequest.first))
    end

    it 'allows creating a branch from the issue page' do
      visit project_issue_path(project, issue)

      select_dropdown_option('create-branch')

      wait_for_requests

      expect(page).to have_selector('.dropdown-toggle-text ', text: '1-cherry-coloured-funk')
      expect(current_path).to eq project_tree_path(project, '1-cherry-coloured-funk')
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

        visit project_issue_path(project, issue)
      end

      it 'disables the create branch button' do
        expect(page).to have_css('.create-mr-dropdown-wrap .unavailable:not(.hide)')
        expect(page).to have_css('.create-mr-dropdown-wrap .available.hide', visible: false)
        expect(page).to have_content /1 Related Merge Request/
      end
    end

    context 'when issue is confidential' do
      it 'disables the create branch button' do
        issue = create(:issue, :confidential, project: project)

        visit project_issue_path(project, issue)

        expect(page).not_to have_css('.create-mr-dropdown-wrap')
      end
    end
  end

  context 'for visitors' do
    before do
      visit project_issue_path(project, issue)
    end

    it 'shows no buttons' do
      expect(page).not_to have_selector('.create-mr-dropdown-wrap')
    end
  end

  def select_dropdown_option(option)
    find('.create-mr-dropdown-wrap .dropdown-toggle').click
    find("li[data-value='#{option}']").click
    find('.js-create-merge-request').click
  end
end
