require 'spec_helper'

describe 'Branches' do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public, :repository) }
  let(:repository) { project.repository }

  context 'logged in as developer' do
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
          Timecop.freeze((threshold + i).ago) { create_file(message: "a commit in stale-#{i}", branch_name: "stale-#{i}") }
        end
        # Add 6 active branches
        (1..6).each do |i|
          Timecop.freeze((threshold - i).ago) { create_file(message: "a commit in active-#{i}", branch_name: "active-#{i}") }
        end
      end

      describe 'Overview page of the branches' do
        it 'shows the first 5 active branches and the first 4 stale branches sorted by last updated' do
          visit project_branches_path(project)

          expect(page).to have_content(sorted_branches(repository, count: 5, sort_by: :updated_desc, state: 'active'))
          expect(page).to have_content(sorted_branches(repository, count: 4, sort_by: :updated_desc, state: 'stale'))

          expect(page).to have_link('Show more active branches', href: project_branches_filtered_path(project, state: 'active'))
          expect(page).not_to have_content('Show more stale branches')
        end
      end

      describe 'Active branches page' do
        it 'shows 6 active branches sorted by last updated' do
          visit project_branches_filtered_path(project, state: 'active')

          expect(page).to have_content(sorted_branches(repository, count: 6, sort_by: :updated_desc, state: 'active'))
        end
      end

      describe 'Stale branches page' do
        it 'shows 4 active branches sorted by last updated' do
          visit project_branches_filtered_path(project, state: 'stale')

          expect(page).to have_content(sorted_branches(repository, count: 4, sort_by: :updated_desc, state: 'stale'))
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

          expect(page).to have_content(sorted_branches(repository, count: Kaminari.config.default_per_page, sort_by: :updated_desc, state: 'active'))
        end

        it 'shows only default_per_page branches sorted by last updated on All branches' do
          visit project_branches_filtered_path(project, state: 'all')

          expect(page).to have_content(sorted_branches(repository, count: Kaminari.config.default_per_page, sort_by: :updated_desc))
        end
      end
    end

    describe 'Find branches' do
      it 'shows filtered branches', :js do
        visit project_branches_path(project)

        fill_in 'branch-search', with: 'fix'
        find('#branch-search').native.send_keys(:enter)

        expect(page).to have_content('fix')
        expect(find('.all-branches')).to have_selector('li', count: 1)
      end
    end

    describe 'Delete unprotected branch on Overview' do
      it 'removes branch after confirmation', :js do
        visit project_branches_filtered_path(project, state: 'all')

        expect(all('.all-branches').last).to have_selector('li', count: 20)
        accept_confirm { find('.js-branch-add-pdf-text-binary .btn-remove').click }

        expect(all('.all-branches').last).to have_selector('li', count: 19)
      end
    end

    describe 'All branches page' do
      it 'shows all the branches sorted by last updated by default' do
        visit project_branches_filtered_path(project, state: 'all')

        expect(page).to have_content(sorted_branches(repository, count: 20, sort_by: :updated_desc))
      end

      it 'sorts the branches by name' do
        visit project_branches_filtered_path(project, state: 'all')

        click_button "Last updated" # Open sorting dropdown
        click_link "Name"

        expect(page).to have_content(sorted_branches(repository, count: 20, sort_by: :name))
      end

      it 'sorts the branches by oldest updated' do
        visit project_branches_filtered_path(project, state: 'all')

        click_button "Last updated" # Open sorting dropdown
        click_link "Oldest updated"

        expect(page).to have_content(sorted_branches(repository, count: 20, sort_by: :updated_asc))
      end

      it 'avoids a N+1 query in branches index' do
        control_count = ActiveRecord::QueryRecorder.new { visit project_branches_path(project) }.count

        %w(one two three four five).each { |ref| repository.add_branch(user, ref, 'master') }

        expect { visit project_branches_filtered_path(project, state: 'all') }.not_to exceed_query_limit(control_count)
      end
    end

    describe 'Find branches on All branches' do
      it 'shows filtered branches', :js do
        visit project_branches_filtered_path(project, state: 'all')

        fill_in 'branch-search', with: 'fix'
        find('#branch-search').native.send_keys(:enter)

        expect(page).to have_content('fix')
        expect(find('.all-branches')).to have_selector('li', count: 1)
      end
    end

    describe 'Delete unprotected branch on All branches' do
      it 'removes branch after confirmation', :js do
        visit project_branches_filtered_path(project, state: 'all')

        fill_in 'branch-search', with: 'fix'

        find('#branch-search').native.send_keys(:enter)

        expect(page).to have_content('fix')
        expect(find('.all-branches')).to have_selector('li', count: 1)
        accept_confirm { find('.js-branch-fix .btn-remove').click }

        expect(page).not_to have_content('fix')
        expect(find('.all-branches')).to have_selector('li', count: 0)
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

  context 'logged in as master' do
    before do
      sign_in(user)
      project.add_master(user)
    end

    describe 'Initial branches page' do
      it 'shows description for admin' do
        visit project_branches_filtered_path(project, state: 'all')

        expect(page).to have_content("Protected branches can be managed in project settings")
      end
    end
  end

  context 'logged out' do
    before do
      visit project_branches_path(project)
    end

    it 'does not show merge request button' do
      page.within first('.all-branches li') do
        expect(page).not_to have_content 'Merge Request'
      end
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

  def create_file(message: 'message', branch_name:)
    repository.create_file(user, generate(:branch), 'content', message: message, branch_name: branch_name)
  end
end
