require 'rails_helper'

describe 'User creates branch and merge request on issue page', :js do
  let(:user) { create(:user) }
  let!(:project) { create(:project, :repository) }
  let(:issue) { create(:issue, project: project, title: 'Cherry-Coloured Funk') }

  context 'when signed out' do
    before do
      visit project_issue_path(project, issue)
    end

    it "doesn't show 'Create merge request' button" do
      expect(page).not_to have_selector('.create-mr-dropdown-wrap')
    end
  end

  context 'when signed in' do
    before do
      project.add_developer(user)

      sign_in(user)
    end

    context 'when interacting with the dropdown' do
      before do
        visit project_issue_path(project, issue)
      end

      it 'shows elements' do
        button_create_merge_request = find('.js-create-merge-request')

        find('.create-mr-dropdown-wrap .dropdown-toggle').click

        page.within('.create-merge-request-dropdown-menu') do
          button_create_target = find('.js-create-target')
          input_branch_name = find('.js-branch-name')
          li_create_branch = find("li[data-value='create-branch']")
          li_create_merge_request = find("li[data-value='create-mr']")

          # Test that all elements are presented.
          expect(page).to have_content('Create merge request and branch')
          expect(page).to have_content('Create branch')
          expect(page).to have_content('Branch name')
          expect(page).to have_content('Source (branch or tag)')
          expect(page).to have_button('Create merge request')

          # Test selection mark
          page.within(li_create_merge_request) do
            expect(page).to have_css('i.fa.fa-check')
            expect(button_create_target).to have_text('Create merge request')
            expect(button_create_merge_request).to have_text('Create merge request')
          end

          li_create_branch.click

          page.within(li_create_branch) do
            expect(page).to have_css('i.fa.fa-check')
            expect(button_create_target).to have_text('Create branch')
            expect(button_create_merge_request).to have_text('Create branch')
          end

          # Test branch name checking
          expect(input_branch_name.value).to eq(issue.to_branch_name)

          input_branch_name.set('new-branch-name')
          branch_name_message = find('.js-branch-message')

          expect(branch_name_message).to have_text('Checking branch name availability…')

          wait_for_requests

          expect(branch_name_message).to have_text('branch name is available')

          input_branch_name.set(project.default_branch)

          expect(branch_name_message).to have_text('Checking branch name availability…')

          wait_for_requests

          expect(branch_name_message).to have_text('Branch is already taken')
        end
      end

      it 'creates a merge request' do
        perform_enqueued_jobs do
          select_dropdown_option('create-mr')

          expect(page).to have_content('WIP: Resolve "Cherry-Coloured Funk"')
          expect(current_path).to eq(project_merge_request_path(project, MergeRequest.first))

          wait_for_requests
        end

        visit project_issue_path(project, issue)

        expect(page).to have_content('created branch 1-cherry-coloured-funk')
        expect(page).to have_content('mentioned in merge request !1')
      end

      it 'creates a branch' do
        select_dropdown_option('create-branch')

        wait_for_requests

        expect(page).to have_selector('.dropdown-toggle-text ', text: '1-cherry-coloured-funk')
        expect(current_path).to eq project_tree_path(project, '1-cherry-coloured-funk')
      end
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

    context 'when merge requests are disabled' do
      before do
        project.project_feature.update(merge_requests_access_level: 0)

        visit project_issue_path(project, issue)
      end

      it 'shows only create branch button' do
        expect(page).not_to have_button('Create merge request')
        expect(page).to have_button('Create branch')
      end
    end

    context 'when issue is confidential' do
      let(:issue) { create(:issue, :confidential, project: project) }

      it 'disables the create branch button' do
        visit project_issue_path(project, issue)

        expect(page).not_to have_css('.create-mr-dropdown-wrap')
      end
    end
  end

  def select_dropdown_option(option)
    find('.create-mr-dropdown-wrap .dropdown-toggle').click
    find("li[data-value='#{option}']").click
    find('.js-create-merge-request').click
  end
end
