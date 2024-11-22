# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Branches', feature_category: :source_code_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public, :repository) }
  let(:repository) { project.repository }

  context 'when logged in as reporter' do
    before do
      sign_in(user)
      project.add_reporter(user)
    end

    it 'does not show delete button' do
      visit project_branches_path(project)

      expect(page).not_to have_css '.js-delete-branch-button'
    end
  end

  context 'when logged in as developer' do
    before do
      sign_in(user)
      project.add_developer(user)
    end

    context 'on the projects with 6 active branches and 4 stale branches' do
      let(:project) { create(:project, :public, :empty_repo) }
      let(:repository) { project.repository }
      let(:threshold) { Gitlab::Git::Branch::STALE_BRANCH_THRESHOLD }

      before do
        # Add 4 stale branches
        (1..4).reverse_each do |i|
          travel_to((threshold + i.hours).ago) do
            create_file(message: "a commit in stale-#{i}", branch_name: "stale-#{i}")
          end
        end
        # Add 6 active branches
        (1..6).each do |i|
          travel_to((threshold - i.hours).ago) do
            create_file(message: "a commit in active-#{i}", branch_name: "active-#{i}")
          end
        end
      end

      describe 'Overview page of the branches' do
        it 'shows the first 5 active branches and the first 4 stale branches sorted by last updated' do
          visit project_branches_path(project)

          expect(page).to have_content(sorted_branches(repository, count: 5, sort_by: :updated_desc, state: 'active'))
          expect(page).to have_content(sorted_branches(repository, count: 4, sort_by: :updated_asc, state: 'stale'))

          expect(page).to have_button('Copy branch name')

          expect(page).to have_link(
            'Show more active branches',
            href: project_branches_filtered_path(project, state: 'active')
          )
          expect(page).not_to have_content('Show more stale branches')
        end
      end

      describe 'Active branches page' do
        it 'shows 6 active branches sorted by last updated' do
          visit project_branches_filtered_path(project, state: 'active')

          expect(page).to have_content(sorted_branches(repository, count: 6, sort_by: :updated_desc, state: 'active'))
        end

        it 'sorts the branches by oldest updated', :js do
          visit project_branches_filtered_path(project, state: 'active')

          click_button 'Updated date'
          within_testid 'branches-dropdown' do
            first('span', text: 'Oldest updated').click
          end

          expect(page).to have_content(sorted_branches(repository, count: 6, sort_by: :updated_asc, state: 'active'))
          expect(page).to have_current_path(
            [project_branches_path(project, state: 'active'), 'sort=updated_asc'].join('&')
          )
        end
      end

      describe 'Stale branches page' do
        it 'shows 4 stale branches sorted by last updated' do
          visit project_branches_filtered_path(project, state: 'stale')

          expect(page).to have_content(sorted_branches(repository, count: 4, sort_by: :updated_asc, state: 'stale'))
        end

        it 'sorts the branches by oldest updated', :js do
          visit project_branches_filtered_path(project, state: 'stale')

          click_button 'Oldest updated'
          within_testid 'branches-dropdown' do
            first('span', text: 'Updated date').click
          end

          expect(page).to have_content(sorted_branches(repository, count: 4, sort_by: :updated_desc, state: 'stale'))
          expect(page).to have_current_path(
            [project_branches_path(project, state: 'stale'), 'sort=updated_desc'].join('&')
          )
        end
      end

      describe 'All branches page' do
        it 'shows 10 branches sorted by last updated' do
          visit project_branches_filtered_path(project, state: 'all')

          expect(page).to have_content(sorted_branches(repository, count: 10, sort_by: :updated_desc))
        end
      end

      context 'with branches over more than one page' do
        before do
          allow(Kaminari.config).to receive(:default_per_page).and_return(5)
        end

        it 'shows only default_per_page active branches sorted by last updated' do
          visit project_branches_filtered_path(project, state: 'active')

          expect(page).to have_content(sorted_branches(
            repository,
            count: Kaminari.config.default_per_page,
            sort_by: :updated_desc,
            state: 'active'
          ))
        end

        it 'shows only default_per_page branches sorted by last updated on All branches' do
          visit project_branches_filtered_path(project, state: 'all')

          expect(page).to have_content(sorted_branches(
            repository,
            count: Kaminari.config.default_per_page,
            sort_by: :updated_desc
          ))
        end
      end
    end

    describe 'Find branches' do
      it 'shows filtered branches', :js do
        visit project_branches_path(project)

        search_for_branch('fix')

        expect(page).to have_content('fix')
        expect(find('.all-branches')).to have_selector('li', count: 1)
      end
    end

    describe 'Delete unprotected branch on Overview' do
      it 'removes branch after confirmation', :js do
        visit project_branches_filtered_path(project, state: 'all')

        expect(all('.all-branches').last).to have_selector('li', count: 20)

        delete_branch_and_confirm

        expect(page).to have_content('Branch was deleted')
      end
    end

    describe 'All branches page' do
      it 'shows all the branches sorted by last updated by default' do
        visit project_branches_filtered_path(project, state: 'all')

        expect(page).to have_content(sorted_branches(repository, count: 20, sort_by: :updated_desc))
      end

      it 'sorts the branches by name', :js do
        visit project_branches_filtered_path(project, state: 'all')

        click_button "Updated date" # Open sorting dropdown
        within_testid 'branches-dropdown' do
          first('span', text: 'Name').click
        end

        expect(page).to have_content(sorted_branches(repository, count: 20, sort_by: :name))
      end

      it 'sorts the branches by oldest updated', :js do
        visit project_branches_filtered_path(project, state: 'all')

        click_button "Updated date" # Open sorting dropdown
        within_testid 'branches-dropdown' do
          first('span', text: 'Oldest updated').click
        end

        expect(page).to have_content(sorted_branches(repository, count: 20, sort_by: :updated_asc))
        expect(page).to have_current_path(
          [project_branches_path(project, state: 'all'), 'sort=updated_asc'].join('&')
        )
      end

      it 'avoids a N+1 query in branches index' do
        new_branches_count = 20
        sql_queries_count_threshold = 10

        control = ActiveRecord::QueryRecorder.new { visit project_branches_path(project) }

        (1..new_branches_count).each { |number| repository.add_branch(user, "new-branch-#{number}", 'master') }

        expect { visit project_branches_filtered_path(project, state: 'all') }
          .not_to exceed_query_limit(control).with_threshold(sql_queries_count_threshold)
      end
    end

    describe 'Find branches on All branches' do
      it 'shows filtered branches', :js do
        visit project_branches_filtered_path(project, state: 'all')

        search_for_branch('fix')

        expect(page).to have_content('fix')
        expect(find('.all-branches')).to have_selector('li', count: 1)
      end
    end

    describe 'Delete unprotected branch on All branches' do
      it 'removes branch after confirmation', :js do
        visit project_branches_filtered_path(project, state: 'all')

        search_for_branch('fix')

        expect(all('.all-branches').last).to have_selector('li', count: 1)

        delete_branch_and_confirm

        expect(page).to have_content('Branch was deleted')

        page.refresh

        search_for_branch('fix')
        clear_search_input
        expect(page).not_to have_content('fix')
        expect(all('.all-branches', wait: false).last).to have_selector('li', count: 0)
      end
    end

    describe 'Link to branch rules' do
      it 'does not have possibility to navigate to branch rules', :js do
        expect(page).not_to have_content(s_("Branches|View branch rules"))
      end
    end

    context 'on project with 0 branch' do
      let(:project) { create(:project, :public, :empty_repo) }
      let(:repository) { project.repository }

      describe '0 branches on Overview' do
        it 'shows warning' do
          visit project_branches_path(project)

          expect(page).not_to have_selector('.all-branches')
        end
      end
    end
  end

  context 'when logged in as maintainer' do
    before do
      sign_in(user)
      project.add_maintainer(user)
    end

    it 'shows the merge request button' do
      visit project_branches_path(project)

      page.within first('.all-branches li') do
        expect(page).to have_content 'New'
      end
    end

    context 'when the project is archived' do
      let(:project) { create(:project, :public, :repository, :archived) }

      it 'does not show the merge request button when the project is archived' do
        visit project_branches_path(project)

        page.within first('.all-branches li') do
          expect(page).not_to have_content 'New'
        end
      end

      describe 'Navigate to branch rules from branches page' do
        it 'shows repository settings page with Branch rules section expanded' do
          visit project_branches_path(project)

          view_branch_rules

          expect(page).to have_content(
            _('Define rules for who can push, merge, and the required approvals for each branch.'))
        end
      end
    end
  end

  describe 'merge request badge', :js do
    let_it_be(:project) { create(:project, :public, :repository) }
    let_it_be(:merge_request) do
      create(
        :merge_request,
        source_project: project,
        target_project: project,
        target_branch: 'master',
        source_branch: 'feature'
      )
    end

    before_all do
      project.project_feature.update_column(:merge_requests_access_level, ProjectFeature::PRIVATE)
    end

    context 'when user has access to merge requests' do
      before do
        project.add_maintainer(user)

        sign_in(user)

        visit project_branches_path(project)
      end

      it 'shows merge request badge' do
        expect(page).to have_selector('.gl-badge', text: merge_request.to_reference)
      end
    end

    context 'when user does not have access to merge requests' do
      before do
        sign_in(user)

        visit project_branches_path(project)
      end

      it 'shows merge request badge' do
        expect(page).not_to have_selector('.gl-badge', text: merge_request.to_reference)
      end
    end
  end

  context 'when logged out' do
    before do
      visit project_branches_path(project)
    end

    it 'does not show merge request button' do
      page.within first('.all-branches li') do
        expect(page).not_to have_content 'New'
      end
    end
  end

  context 'with one or more pipeline', :js do
    let_it_be(:project) { create(:project, :public, :empty_repo) }

    before do
      sha = create_file(branch_name: "branch")
      create(:ci_pipeline,
        project: project,
        user: user,
        ref: "branch",
        sha: sha,
        status: :success,
        created_at: 5.months.ago)
      visit project_branches_path(project)
    end

    it 'shows pipeline status when available' do
      page.within first('.all-branches li') do
        expect(page).to have_css '[data-testid="status_success_borderless-icon"]'
      end
    end

    it 'displays a placeholder when not available' do
      page.all('.all-branches li') do |li|
        expect(li).to have_css '.pipeline-status svg.s24'
      end
    end
  end

  context 'with no pipelines', :js do
    before do
      visit project_branches_path(project)
    end

    it 'does not show placeholder or pipeline status' do
      page.all('.all-branches') do |branches|
        expect(branches).not_to have_css '.pipeline-status svg.s24'
      end
    end
  end

  describe 'comparing branches' do
    before do
      sign_in(user)
      project.add_developer(user)
    end

    shared_examples 'compares branches' do
      it 'compares branches' do
        visit project_branches_path(project)

        page.within first('.all-branches li') do
          wait_for_requests
          within_testid('branch-more-actions') do
            find('.gl-new-dropdown-toggle').click
          end
          click_link 'Compare'
        end

        expect(page).to have_content 'Commits'
      end
    end

    context 'on a read-only instance', :js do
      before do
        allow(Gitlab::Database).to receive(:read_only?).and_return(true)
      end

      it_behaves_like 'compares branches'
    end

    context 'on a read-write instance', :js do
      it_behaves_like 'compares branches'
    end
  end

  def sorted_branches(repository, count:, sort_by:, state: nil)
    branches = repository.branches_sorted_by(sort_by)
    branches = branches.select { |b| state == 'active' ? b.active? : b.stale? } if state
    sorted_branches =
      branches.first(count).map do |branch|
        Regexp.escape(branch.name)
      end

    Regexp.new(sorted_branches.join('.*'))
  end

  def create_file(branch_name:, message: 'message')
    repository.create_file(user, generate(:branch), 'content', message: message, branch_name: branch_name)
  end

  def search_for_branch(name)
    branch_search = find('input[data-testid="branch-search"]')
    branch_search.set(name)
    branch_search.native.send_keys(:enter)
  end

  def clear_search_input
    find('input[data-testid="branch-search"]').set('')
  end

  def delete_branch_and_confirm
    wait_for_requests
    within_testid('branch-more-actions', match: :first) do
      find('.gl-new-dropdown-toggle', match: :first).click
    end
    find_by_testid('delete-branch-button').click

    within '.modal-footer' do
      click_button 'Yes, delete branch'
    end
  end

  def view_branch_rules
    page.within('.nav-controls') do
      click_link s_("Branches|View branch rules")
    end
    wait_for_requests
  end
end
