# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge Request > Selecting projects with different visibility', feature_category: :source_code_management do
  include ProjectForksHelper

  let_it_be(:public_project) { create(:project, :public, :small_repo) }
  let_it_be(:internal_project) { create(:project, :internal, :small_repo) }
  let_it_be(:private_project) { create(:project, :private, :small_repo) }
  let(:private_fork_public_project) do
    fork_project(public_project, nil, target_project: create(:project, :private, :small_repo))
  end

  let(:private_fork_internal_project) do
    fork_project(internal_project, nil, target_project: create(:project, :private, :small_repo))
  end

  let(:internal_fork_public_project) do
    fork_project(public_project, nil, target_project: create(:project, :internal, :small_repo))
  end

  let(:user) { source_project.creator }

  before do
    sign_in(user)
  end

  describe 'warnings for more permissive visibility in target project', :js do
    using RSpec::Parameterized::TableSyntax

    where(:source_project, :target_project, :warning_message) do
      ref(:private_fork_internal_project) |
        ref(:internal_project) |
        _('This merge request is from a private project to an internal project.')

      ref(:private_fork_public_project) |
        ref(:public_project) |
        _('This merge request is from a private project to a public project.')

      ref(:internal_fork_public_project) |
        ref(:public_project) |
        _('This merge request is from an internal project to a public project.')
    end

    with_them do
      it 'shows a warning message' do
        visit project_new_merge_request_path(source_project,
          merge_request: { source_branch: 'master', target_project_id: target_project.id })
        expect(page).to have_content(warning_message)
      end
    end

    describe 'warnings for more permissive repository access level in target project' do
      let(:source_project) do
        fork_project(internal_project, nil, target_project: create(:project, :internal, :small_repo))
      end

      let(:target_project) { internal_project }

      let(:warning_message) do
        "Project #{source_project.name_with_namespace} has more restricted access settings than " \
          "#{target_project.name_with_namespace}. To avoid exposing private changes, make sure " \
          "you're submitting changes to the correct project."
      end

      context 'when the source repository access level is private' do
        before do
          source_access_level = Featurable::PRIVATE
          source_project.project_feature.update!(
            repository_access_level: source_access_level,
            merge_requests_access_level: source_access_level,
            builds_access_level: source_access_level
          )
        end

        it 'shows a warning' do
          visit project_new_merge_request_path(source_project,
            merge_request: { source_branch: 'master', target_project_id: target_project.id })
          expect(page).to have_content(warning_message)
        end

        context 'when target project is private' do
          let(:source_project) do
            fork_project(private_project, nil, target_project: create(:project, :private, :small_repo))
          end

          let(:target_project) { private_project }

          it 'does not show a warning' do
            visit project_new_merge_request_path(source_project,
              merge_request: { source_branch: 'master', target_project_id: target_project.id })

            expect(page).not_to have_content(warning_message)
          end
        end
      end
    end
  end
end
