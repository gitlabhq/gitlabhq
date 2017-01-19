require 'spec_helper'

feature 'Merge Request buttons on branches page', feature: true do
  let(:user) { create(:user) }
  let(:project) { create(:project) }

  context 'not logged in' do
    it 'does not show merge request buttons' do
      visit namespace_project_branches_path(project.namespace, project)

      expect(page).to have_no_link('Merge Request')
    end
  end

  context 'logged in a developer' do
    before do
      login_as(user)
      project.team << [user, :developer]
    end

    it 'shows merge request buttons' do
      href = new_namespace_project_merge_request_path(project.namespace,
                                                      project,
                                                      merge_request: { source_branch: 'feature',
                                                                       target_branch: 'master' })

      visit namespace_project_branches_path(project.namespace, project)

      expect(page).to have_link('Merge Request', href: href)
    end
  end

  context 'logged in as non-member' do
    before do
      login_as(user)
    end

    it 'does not show merge request buttons' do
      visit namespace_project_branches_path(project.namespace, project)

      expect(page).to have_no_link('Merge Request')
    end

    context 'on own fork of project' do
      let(:forked_project) do
        create(:project, forked_from_project: project)
      end
      let(:user) { forked_project.owner }

      it 'shows merge request buttons' do
        href = new_namespace_project_merge_request_path(forked_project.namespace,
                                                        forked_project,
                                                        merge_request: { source_branch: 'feature',
                                                                         target_branch: 'master' })

        visit namespace_project_branches_path(forked_project.namespace, forked_project)

        expect(page).to have_link('Merge Request', href: href)
      end
    end
  end
end
