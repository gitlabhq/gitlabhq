require 'spec_helper'

describe 'Branches' do
  include EE::ProtectedBranchHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project, :public, :repository) }
  let(:repository) { project.repository }

  context 'logged in as developer' do
    before do
      sign_in(user)
      project.add_developer(user)
    end

    describe 'Initial branches page' do
      it 'shows all the branches sorted by last updated by default' do
        visit project_branches_path(project)

        expect(page).to have_content(sorted_branches(repository, count: 20, sort_by: :updated_desc))
      end

      it 'sorts the branches by name' do
        visit project_branches_path(project)

        click_button "Last updated" # Open sorting dropdown
        click_link "Name"

        expect(page).to have_content(sorted_branches(repository, count: 20, sort_by: :name))
      end

      it 'sorts the branches by oldest updated' do
        visit project_branches_path(project)

        click_button "Last updated" # Open sorting dropdown
        click_link "Oldest updated"

        expect(page).to have_content(sorted_branches(repository, count: 20, sort_by: :updated_asc))
      end

      it 'avoids a N+1 query in branches index' do
        control_count = ActiveRecord::QueryRecorder.new { visit project_branches_path(project) }.count

        %w(one two three four five).each { |ref| repository.add_branch(user, ref, 'master') }

        expect { visit project_branches_path(project) }.not_to exceed_query_limit(control_count)
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

    describe 'Delete unprotected branch' do
      it 'removes branch after confirmation', :js do
        visit project_branches_path(project)

        fill_in 'branch-search', with: 'fix'

        find('#branch-search').native.send_keys(:enter)

        expect(page).to have_content('fix')
        expect(find('.all-branches')).to have_selector('li', count: 1)
        accept_confirm { find('.js-branch-fix .btn-remove').click }

        expect(page).not_to have_content('fix')
        expect(find('.all-branches')).to have_selector('li', count: 0)
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
        visit project_branches_path(project)

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

  def sorted_branches(repository, count:, sort_by:)
    sorted_branches =
      repository.branches_sorted_by(sort_by).first(count).map do |branch|
        Regexp.escape(branch.name)
      end

    Regexp.new(sorted_branches.join('.*'))
  end
end
