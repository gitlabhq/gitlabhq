require 'spec_helper'

feature 'Merge Request button', feature: true do
  shared_examples 'Merge request button only shown when allowed' do
    let(:user) { create(:user) }
    let(:project) { create(:project, :public) }
    let(:forked_project) { create(:project, :public, forked_from_project: project) }

    context 'not logged in' do
      it 'does not show Create merge request button' do
        visit url

        within("#content-body") do
          expect(page).not_to have_link(label)
        end
      end
    end

    context 'logged in as developer' do
      before do
        login_as(user)
        project.team << [user, :developer]
      end

      it 'shows Create merge request button' do
        href = new_namespace_project_merge_request_path(project.namespace,
                                                        project,
                                                        merge_request: { source_branch: "'test'",
                                                                         target_branch: 'master' })

        visit url

        within("#content-body") do
          expect(page).to have_link(label, href: href)
        end
      end

      context 'merge requests are disabled' do
        before do
          project.project_feature.update!(merge_requests_access_level: ProjectFeature::DISABLED)
        end

        it 'does not show Create merge request button' do
          visit url

          within("#content-body") do
            expect(page).not_to have_link(label)
          end
        end
      end
    end

    context 'logged in as non-member' do
      before do
        login_as(user)
      end

      it 'does not show Create merge request button' do
        visit url

        within("#content-body") do
          expect(page).not_to have_link(label)
        end
      end

      context 'on own fork of project' do
        let(:user) { forked_project.owner }

        it 'shows Create merge request button' do
          href = new_namespace_project_merge_request_path(forked_project.namespace,
                                                          forked_project,
                                                          merge_request: { source_branch: "'test'",
                                                                           target_branch: 'master' })

          visit fork_url

          within("#content-body") do
            expect(page).to have_link(label, href: href)
          end
        end
      end
    end
  end

  context 'on branches page' do
    it_behaves_like 'Merge request button only shown when allowed' do
      let(:label) { 'Merge request' }
      let(:url) { namespace_project_branches_path(project.namespace, project, search: 'feature') }
      let(:fork_url) { namespace_project_branches_path(forked_project.namespace, forked_project, search: 'feature') }
    end
  end

  context 'on compare page' do
    it_behaves_like 'Merge request button only shown when allowed' do
      let(:label) { 'Create merge request' }
      let(:url) { namespace_project_compare_path(project.namespace, project, from: 'master', to: "'test'") }
      let(:fork_url) { namespace_project_compare_path(forked_project.namespace, forked_project, from: 'master', to: "'test'") }
    end
  end

  context 'on commits page' do
    it_behaves_like 'Merge request button only shown when allowed' do
      let(:label) { 'Create merge request' }
      let(:url) { namespace_project_commits_path(project.namespace, project, "'test'") }
      let(:fork_url) { namespace_project_commits_path(forked_project.namespace, forked_project, "'test'") }
    end
  end
end
