require 'spec_helper'

describe 'Branches', feature: true do
  let(:project) { create(:project, :public) }
  let(:repository) { project.repository }

  def set_protected_branch_name(branch_name)
    find(".js-protected-branch-select").click
    find(".dropdown-input-field").set(branch_name)
    click_on("Create wildcard #{branch_name}")
  end

  context 'logged in as developer' do
    before do
      login_as :user
      project.team << [@user, :developer]
    end

    describe 'Initial branches page' do
      it 'shows all the branches' do
        visit namespace_project_branches_path(project.namespace, project)

        repository.branches { |branch| expect(page).to have_content("#{branch.name}") }
        expect(page).to have_content("Protected branches can be managed in project settings")
      end

      it 'avoids a N+1 query in branches index' do
        control_count = ActiveRecord::QueryRecorder.new { visit namespace_project_branches_path(project.namespace, project) }.count

        %w(one two three four five).each { |ref| repository.add_branch(@user, ref, 'master') }

        expect { visit namespace_project_branches_path(project.namespace, project) }.not_to exceed_query_limit(control_count)
      end
    end

    describe 'Find branches' do
      it 'shows filtered branches', js: true do
        visit namespace_project_branches_path(project.namespace, project)

        fill_in 'branch-search', with: 'fix'
        find('#branch-search').native.send_keys(:enter)

        expect(page).to have_content('fix')
        expect(find('.all-branches')).to have_selector('li', count: 1)
      end
    end

    describe 'Delete unprotected branch' do
      it 'removes branch after confirmation', js: true do
        visit namespace_project_branches_path(project.namespace, project)

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
        project.add_user(@user, :master)
        visit namespace_project_protected_branches_path(project.namespace, project)
        set_protected_branch_name('fix')
        click_on "Protect"

        within(".protected-branches-list") { expect(page).to have_content('fix') }
        expect(ProtectedBranch.count).to eq(1)
        project.add_user(@user, :developer)
      end

      it 'does not allow devleoper to removes protected branch', js: true do
        visit namespace_project_branches_path(project.namespace, project)

        fill_in 'branch-search', with: 'fix'
        find('#branch-search').native.send_keys(:enter)

        expect(page).to have_css('.btn-remove.disabled')
      end
    end
  end

  context 'logged in as master' do
    before do
      login_as :user
      project.team << [@user, :master]
    end

    describe 'Delete protected branch' do
      before do
        visit namespace_project_protected_branches_path(project.namespace, project)
        set_protected_branch_name('fix')
        click_on "Protect"

        within(".protected-branches-list") { expect(page).to have_content('fix') }
        expect(ProtectedBranch.count).to eq(1)
      end

      it 'removes branch after modal confirmation', js: true do
        visit namespace_project_branches_path(project.namespace, project)

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
      visit namespace_project_branches_path(project.namespace, project)
    end

    it 'does not show merge request button' do
      page.within first('.all-branches li') do
        expect(page).not_to have_content 'Merge Request'
      end
    end
  end
end
