require 'spec_helper'

feature 'Merge Request button on commits page', feature: true do
  let(:user) { create(:user) }
  let(:project) { create(:project) }

  context 'not logged in' do
    it 'does not show Create Merge Request button' do
      visit namespace_project_compare_path(project.namespace, project, from: 'master', to: 'feature')

      expect(page).to have_no_link('Create Merge Request')
    end
  end

  context 'logged in a developer' do
    before do
      login_as(user)
      project.team << [user, :developer]
    end

    it 'shows Create Merge Request button' do
      href = new_namespace_project_merge_request_path(project.namespace,
                                                      project,
                                                      merge_request: { source_branch: 'feature',
                                                                       target_branch: 'master' })

      visit namespace_project_compare_path(project.namespace, project, from: 'master', to: 'feature')

      expect(page).to have_link('Create Merge Request', href: href)
    end
  end

  context 'logged in as non-member' do
    before do
      login_as(user)
    end

    it 'does not show Create Merge Request button' do
      visit namespace_project_compare_path(project.namespace, project, from: 'master', to: 'feature')

      expect(page).to have_no_link('Create Merge Request')
    end

    context 'on own fork of project' do
      let(:forked_project) do
        create(:project, forked_from_project: project)
      end
      let(:user) { forked_project.owner }

      it 'shows Create Merge Request button' do
        href = new_namespace_project_merge_request_path(forked_project.namespace,
                                                        forked_project,
                                                        merge_request: { source_branch: 'feature',
                                                                         target_branch: 'master' })

        visit namespace_project_compare_path(forked_project.namespace, forked_project, from: 'master', to: 'feature')

        expect(page).to have_link('Create Merge Request', href: href)
      end
    end
  end
end
