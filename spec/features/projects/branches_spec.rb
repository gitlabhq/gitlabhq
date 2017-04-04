require 'spec_helper'

describe 'Branches', feature: true do
  let(:project) { create(:project, :public) }
  let(:repository) { project.repository }

  context 'logged in' do
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
