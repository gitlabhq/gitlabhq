require 'spec_helper'

describe 'Branches', feature: true do
  include ProtectedBranchHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project, :public) }
  let(:repository) { project.repository }

  context 'logged in as developer' do
    before do
      sign_in(user)
      project.team << [user, :developer]
    end

    describe 'Initial branches page' do
      it 'shows all the branches' do
        visit project_branches_path(project)

        repository.branches_sorted_by(:name).first(20).each do |branch|
          expect(page).to have_content("#{branch.name}")
        end
      end

      it 'sorts the branches by name' do
        visit project_branches_path(project)

        click_button "Name" # Open sorting dropdown
        click_link "Name"

        sorted = repository.branches_sorted_by(:name).first(20).map do |branch|
          Regexp.escape(branch.name)
        end
        expect(page).to have_content(/#{sorted.join(".*")}/)
      end

      it 'sorts the branches by last updated' do
        visit project_branches_path(project)

        click_button "Name" # Open sorting dropdown
        click_link "Last updated"

        sorted = repository.branches_sorted_by(:updated_desc).first(20).map do |branch|
          Regexp.escape(branch.name)
        end
        expect(page).to have_content(/#{sorted.join(".*")}/)
      end

      it 'sorts the branches by oldest updated' do
        visit project_branches_path(project)

        click_button "Name" # Open sorting dropdown
        click_link "Oldest updated"

        sorted = repository.branches_sorted_by(:updated_asc).first(20).map do |branch|
          Regexp.escape(branch.name)
        end
        expect(page).to have_content(/#{sorted.join(".*")}/)
      end

      it 'avoids a N+1 query in branches index' do
        control_count = ActiveRecord::QueryRecorder.new { visit project_branches_path(project) }.count

        %w(one two three four five).each { |ref| repository.add_branch(user, ref, 'master') }

        expect { visit project_branches_path(project) }.not_to exceed_query_limit(control_count)
      end
    end

    describe 'Find branches' do
      it 'shows filtered branches', js: true do
        visit project_branches_path(project)

        fill_in 'branch-search', with: 'fix'
        find('#branch-search').native.send_keys(:enter)

        expect(page).to have_content('fix')
        expect(find('.all-branches')).to have_selector('li', count: 1)
      end
    end

    describe 'Delete unprotected branch' do
      it 'removes branch after confirmation', js: true do
        visit project_branches_path(project)

        fill_in 'branch-search', with: 'fix'

        find('#branch-search').native.send_keys(:enter)

        expect(page).to have_content('fix')
        expect(find('.all-branches')).to have_selector('li', count: 1)
        find('.js-branch-fix .btn-remove').trigger(:click)

        expect(page).not_to have_content('fix')
        expect(find('.all-branches')).to have_selector('li', count: 0)
      end
    end

    describe 'Delete protected branch' do
      before do
        project.add_user(user, :master)
        visit project_protected_branches_path(project)
        set_protected_branch_name('fix')
        set_allowed_to('merge')
        set_allowed_to('push')
        click_on "Protect"

        within(".protected-branches-list") { expect(page).to have_content('fix') }
        expect(ProtectedBranch.count).to eq(1)
        project.add_user(user, :developer)
      end

      it 'does not allow devleoper to removes protected branch', js: true do
        visit project_branches_path(project)

        fill_in 'branch-search', with: 'fix'
        find('#branch-search').native.send_keys(:enter)

        expect(page).to have_css('.btn-remove.disabled')
      end
    end
  end

  context 'logged in as master' do
    before do
      sign_in(user)
      project.team << [user, :master]
    end

    describe 'Initial branches page' do
      it 'shows description for admin' do
        visit project_branches_path(project)

        expect(page).to have_content("Protected branches can be managed in project settings")
      end
    end

    describe 'Delete protected branch' do
      before do
        visit project_protected_branches_path(project)
        set_protected_branch_name('fix')
        set_allowed_to('merge')
        set_allowed_to('push')
        click_on "Protect"

        within(".protected-branches-list") { expect(page).to have_content('fix') }
        expect(ProtectedBranch.count).to eq(1)
      end

      it 'removes branch after modal confirmation', js: true do
        visit project_branches_path(project)

        fill_in 'branch-search', with: 'fix'
        find('#branch-search').native.send_keys(:enter)

        expect(page).to have_content('fix')
        expect(find('.all-branches')).to have_selector('li', count: 1)
        page.find('[data-target="#modal-delete-branch"]').trigger(:click)

        expect(page).to have_css('.js-delete-branch[disabled]')
        fill_in 'delete_branch_input', with: 'fix'
        click_link 'Delete protected branch'

        fill_in 'branch-search', with: 'fix'
        find('#branch-search').native.send_keys(:enter)

        expect(page).to have_content('No branches to show')
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
end
