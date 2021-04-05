# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User creates branch and merge request on issue page', :js do
  let(:membership_level) { :developer }
  let(:user) { create(:user) }
  let!(:project) { create(:project, :repository, :public) }
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
      project.add_user(user, membership_level)

      sign_in(user)
    end

    context 'when interacting with the dropdown' do
      before do
        visit project_issue_path(project, issue)
      end

      # In order to improve tests performance, all UI checks are placed in this test.
      it 'shows elements', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/27993' do
        button_create_merge_request = find('.js-create-merge-request')
        button_toggle_dropdown = find('.create-mr-dropdown-wrap .dropdown-toggle')

        button_toggle_dropdown.click

        dropdown = find('.create-merge-request-dropdown-menu')

        page.within(dropdown) do
          button_create_target = find('.js-create-target')
          input_branch_name = find('.js-branch-name')
          input_source = find('.js-ref')
          li_create_branch = find("li[data-value='create-branch']")
          li_create_merge_request = find("li[data-value='create-mr']")

          # Test that all elements are presented.
          expect(page).to have_content('Create merge request and branch')
          expect(page).to have_content('Create branch')
          expect(page).to have_content('Branch name')
          expect(page).to have_content('Source (branch or tag)')
          expect(page).to have_button('Create merge request')
          expect(page).to have_selector('.js-branch-name:focus')

          test_selection_mark(li_create_branch, li_create_merge_request, button_create_target, button_create_merge_request)
          test_branch_name_checking(input_branch_name)
          test_source_checking(input_source)

          # The button inside dropdown should be disabled if any errors occurred.
          expect(page).to have_button('Create branch', disabled: true)
        end

        # The top level button should be disabled if any errors occurred.
        expect(page).to have_button('Create branch', disabled: true)
      end

      context 'when branch name is auto-generated' do
        it 'creates a merge request', :sidekiq_might_not_need_inline do
          perform_enqueued_jobs do
            select_dropdown_option('create-mr')

            expect(page).to have_content('Draft: Resolve "Cherry-Coloured Funk"')
            expect(current_path).to eq(project_merge_request_path(project, MergeRequest.first))

            wait_for_requests
          end

          visit project_issue_path(project, issue)

          expect(page).to have_content("created merge request !1 to address this issue")
          expect(page).to have_content('mentioned in merge request !1')
        end

        it 'creates a branch' do
          select_dropdown_option('create-branch')

          wait_for_requests

          expect(page).to have_selector('.dropdown-toggle-text ', text: '1-cherry-coloured-funk')
          expect(current_path).to eq project_tree_path(project, '1-cherry-coloured-funk')
        end
      end

      context 'when branch name is custom' do
        let(:branch_name) { 'custom-branch-name' }

        it 'creates a merge request', :sidekiq_might_not_need_inline do
          perform_enqueued_jobs do
            select_dropdown_option('create-mr', branch_name)

            expect(page).to have_content('Draft: Resolve "Cherry-Coloured Funk"')
            expect(page).to have_content('Request to merge custom-branch-name into')
            expect(current_path).to eq(project_merge_request_path(project, MergeRequest.first))

            wait_for_requests
          end

          visit project_issue_path(project, issue)

          expect(page).to have_content("created merge request !1 to address this issue")
          expect(page).to have_content('mentioned in merge request !1')
        end

        it 'creates a branch' do
          select_dropdown_option('create-branch', branch_name)

          wait_for_requests

          expect(page).to have_selector('.dropdown-toggle-text ', text: branch_name)
          expect(current_path).to eq project_tree_path(project, branch_name)
        end
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

      it 'disables the create branch button', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/27985' do
        expect(page).to have_css('.create-mr-dropdown-wrap .unavailable:not(.hidden)')
        expect(page).to have_css('.create-mr-dropdown-wrap .available.hidden', visible: false)
        expect(page).to have_content /Related merge requests/
      end
    end

    context 'when merge requests are disabled' do
      before do
        project.project_feature.update!(merge_requests_access_level: 0)

        visit project_issue_path(project, issue)
      end

      it 'shows only create branch button' do
        expect(page).not_to have_button('Create merge request')
        expect(page).to have_button('Create branch')
      end
    end

    context 'when issue is confidential' do
      let(:issue) { create(:issue, :confidential, project: project) }

      it 'enables the create branch button' do
        visit project_issue_path(project, issue)

        expect(page).to have_css('.create-mr-dropdown-wrap')
        expect(page).to have_button('Create confidential merge request')
      end
    end

    context 'when related branch exists' do
      let!(:project) { create(:project, :repository, :private) }
      let(:branch_name) { "#{issue.iid}-foo" }

      before do
        project.repository.create_branch(branch_name)

        visit project_issue_path(project, issue)
      end

      context 'when user is developer' do
        it 'shows related branches' do
          expect(page).to have_css('#related-branches')

          wait_for_requests

          expect(page).to have_content(branch_name)
        end
      end

      context 'when user is guest' do
        let(:membership_level) { :guest }

        it 'does not show related branches' do
          expect(page).not_to have_css('#related-branches')

          wait_for_requests

          expect(page).not_to have_content(branch_name)
        end
      end
    end
  end

  private

  def select_dropdown_option(option, branch_name = nil)
    find('.create-mr-dropdown-wrap .dropdown-toggle').click
    find("li[data-value='#{option}']").click

    if branch_name
      find('.js-branch-name').set(branch_name)

      # Javascript debounces AJAX calls.
      # So we have to wait until AJAX requests are started.
      # Details are in app/assets/javascripts/create_merge_request_dropdown.js
      # this.refDebounce = _.debounce(...)
      sleep 0.5

      wait_for_requests
    end

    find('.js-create-merge-request').click
  end

  def test_branch_name_checking(input_branch_name)
    expect(input_branch_name.value).to eq(issue.to_branch_name)

    input_branch_name.set('new-branch-name')
    branch_name_message = find('.js-branch-message')

    expect(branch_name_message).to have_text('Checking branch name availability…')

    wait_for_requests

    expect(branch_name_message).to have_text('Branch name is available')

    input_branch_name.set(project.default_branch)

    expect(branch_name_message).to have_text('Checking branch name availability…')

    wait_for_requests

    expect(branch_name_message).to have_text('Branch is already taken')
  end

  def test_selection_mark(li_create_branch, li_create_merge_request, button_create_target, button_create_merge_request)
    page.within(li_create_merge_request) do
      expect(page).to have_selector('[data-testid="check-icon"]')
      expect(button_create_target).to have_text('Create merge request')
      expect(button_create_merge_request).to have_text('Create merge request')
    end

    li_create_branch.click

    page.within(li_create_branch) do
      expect(page).to have_selector('[data-testid="check-icon"]')
      expect(button_create_target).to have_text('Create branch')
      expect(button_create_merge_request).to have_text('Create branch')
    end
  end

  def test_source_checking(input_source)
    expect(input_source.value).to eq(project.default_branch)

    input_source.set('mas') # Intentionally entered first 3 letters of `master` to check autocomplete feature later.
    source_message = find('.js-ref-message')

    expect(source_message).to have_text('Checking source availability…')

    wait_for_requests

    expect(source_message).to have_text('Source is not available')

    # JavaScript gets refs started with `mas` (entered above) and places the first match.
    # User sees `mas` in black color (the part they entered) and the `ter` in gray color (a hint).
    # Since hinting is implemented via text selection and rspec/capybara doesn't have matchers for it,
    # we just checking the whole source name.
    expect(input_source.value).to eq(project.default_branch)
  end
end
