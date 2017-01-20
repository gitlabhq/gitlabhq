require 'spec_helper'

feature 'Merge Request button', feature: true do
  shared_examples 'Merge Request button only shown when allowed' do
    let(:user) { create(:user) }
    let(:project) { create(:project) }
    let(:forked_project) { create(:project, forked_from_project: project) }

    context 'not logged in' do
      it 'does not show Create Merge Request button' do
        visit url

        expect(page).not_to have_link(label)
      end
    end

    context 'logged in as developer' do
      before do
        login_as(user)
        project.team << [user, :developer]
      end

      it 'shows Create Merge Request button' do
        href = new_namespace_project_merge_request_path(project.namespace,
                                                        project,
                                                        merge_request: { source_branch: 'feature',
                                                                         target_branch: 'master' })

        visit url

        expect(page).to have_link(label, href: href)
      end
    end

    context 'logged in as non-member' do
      before do
        login_as(user)
      end

      it 'does not show Create Merge Request button' do
        visit url

        expect(page).not_to have_link(label)
      end

      context 'on own fork of project' do
        let(:user) { forked_project.owner }

        it 'shows Create Merge Request button' do
          href = new_namespace_project_merge_request_path(forked_project.namespace,
                                                          forked_project,
                                                          merge_request: { source_branch: 'feature',
                                                                           target_branch: 'master' })

          visit fork_url

          expect(page).to have_link(label, href: href)
        end
      end
    end
  end

  context 'on branches page' do
    it_behaves_like 'Merge Request button only shown when allowed' do
      let(:label) { 'Merge Request' }
      let(:url) { namespace_project_branches_path(project.namespace, project) }
      let(:fork_url) { namespace_project_branches_path(forked_project.namespace, forked_project) }
    end
  end

  context 'on compare page' do
    it_behaves_like 'Merge Request button only shown when allowed' do
      let(:label) { 'Create Merge Request' }
      let(:url) { namespace_project_compare_path(project.namespace, project, from: 'master', to: 'feature') }
      let(:fork_url) { namespace_project_compare_path(forked_project.namespace, forked_project, from: 'master', to: 'feature') }
    end
  end

  context 'on commits page' do
    it_behaves_like 'Merge Request button only shown when allowed' do
      let(:label) { 'Create Merge Request' }
      let(:url) { namespace_project_commits_path(project.namespace, project, 'feature') }
      let(:fork_url) { namespace_project_commits_path(forked_project.namespace, forked_project, 'feature') }
    end
  end
end
