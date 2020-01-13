# frozen_string_literal: true

require 'spec_helper'

describe MergeRequestsFinder do
  context "multiple projects with merge requests" do
    include_context 'MergeRequestsFinder multiple projects with merge requests context'

    describe '#execute' do
      it 'filters by scope' do
        params = { scope: 'authored', state: 'opened' }

        merge_requests = described_class.new(user, params).execute

        expect(merge_requests).to contain_exactly(merge_request1, merge_request4, merge_request5)
      end

      it 'filters by project_id' do
        params = { project_id: project1.id, scope: 'authored', state: 'opened' }

        merge_requests = described_class.new(user, params).execute

        expect(merge_requests).to contain_exactly(merge_request1)
      end

      it 'filters by nonexistent author ID and MR term using CTE for search' do
        params = {
          author_id: 'does-not-exist',
          search: 'git',
          attempt_group_search_optimizations: true
        }

        merge_requests = described_class.new(user, params).execute

        expect(merge_requests).to be_empty
      end

      it 'filters by projects' do
        params = { projects: [project2.id, project3.id] }

        merge_requests = described_class.new(user, params).execute

        expect(merge_requests).to contain_exactly(merge_request3, merge_request4)
      end

      it 'filters by commit sha' do
        merge_requests = described_class.new(
          user,
          commit_sha: merge_request5.merge_request_diff.last_commit_sha
        ).execute

        expect(merge_requests).to contain_exactly(merge_request5)
      end

      context 'filtering by group' do
        it 'includes all merge requests when user has access excluding merge requests from projects the user does not have access to' do
          private_project = allow_gitaly_n_plus_1 { create(:project, :private, group: group) }
          private_project.add_guest(user)
          create(:merge_request, :simple, author: user, source_project: private_project, target_project: private_project)
          params = { group_id: group.id }

          merge_requests = described_class.new(user, params).execute

          expect(merge_requests).to contain_exactly(merge_request1, merge_request2)
        end

        it 'filters by group including subgroups' do
          params = { group_id: group.id, include_subgroups: true }

          merge_requests = described_class.new(user, params).execute

          expect(merge_requests).to contain_exactly(merge_request1, merge_request2, merge_request5)
        end

        it 'filters by group projects including subgroups' do
          # project3 is not in the group, so it should not return merge_request4
          projects = [project3.id, project4.id]
          params = { group_id: group.id, include_subgroups: true, projects: projects }

          merge_requests = described_class.new(user, params).execute

          expect(merge_requests).to contain_exactly(merge_request5)
        end
      end

      it 'filters by non_archived' do
        params = { non_archived: true }

        merge_requests = described_class.new(user, params).execute

        expect(merge_requests).to contain_exactly(merge_request1, merge_request2, merge_request3, merge_request5)
      end

      it 'filters by iid' do
        params = { project_id: project1.id, iids: merge_request1.iid }

        merge_requests = described_class.new(user, params).execute

        expect(merge_requests).to contain_exactly(merge_request1)
      end

      it 'filters by source branch' do
        params = { source_branch: merge_request2.source_branch }

        merge_requests = described_class.new(user, params).execute

        expect(merge_requests).to contain_exactly(merge_request2)
      end

      it 'filters by target branch' do
        params = { target_branch: merge_request2.target_branch }

        merge_requests = described_class.new(user, params).execute

        expect(merge_requests).to contain_exactly(merge_request2)
      end

      it 'filters by source project id' do
        params = { source_project_id: merge_request2.source_project_id }

        merge_requests = described_class.new(user, params).execute

        expect(merge_requests).to contain_exactly(merge_request1, merge_request2, merge_request3)
      end

      it 'filters by state' do
        params = { state: 'locked' }

        merge_requests = described_class.new(user, params).execute

        expect(merge_requests).to contain_exactly(merge_request3)
      end

      describe 'WIP state' do
        let!(:wip_merge_request1) { create(:merge_request, :simple, author: user, source_project: project5, target_project: project5, title: 'WIP: thing') }
        let!(:wip_merge_request2) { create(:merge_request, :simple, author: user, source_project: project6, target_project: project6, title: 'wip thing') }
        let!(:wip_merge_request3) { create(:merge_request, :simple, author: user, source_project: project1, target_project: project1, title: '[wip] thing') }
        let!(:wip_merge_request4) { create(:merge_request, :simple, author: user, source_project: project1, target_project: project2, title: 'wip: thing') }

        it 'filters by wip' do
          params = { wip: 'yes' }

          merge_requests = described_class.new(user, params).execute

          expect(merge_requests).to contain_exactly(merge_request4, merge_request5, wip_merge_request1, wip_merge_request2, wip_merge_request3, wip_merge_request4)
        end

        it 'filters by not wip' do
          params = { wip: 'no' }

          merge_requests = described_class.new(user, params).execute

          expect(merge_requests).to contain_exactly(merge_request1, merge_request2, merge_request3)
        end

        it 'returns all items if no valid wip param exists' do
          params = { wip: '' }

          merge_requests = described_class.new(user, params).execute

          expect(merge_requests).to contain_exactly(merge_request1, merge_request2, merge_request3, merge_request4, merge_request5, wip_merge_request1, wip_merge_request2, wip_merge_request3, wip_merge_request4)
        end

        it 'adds wip to scalar params' do
          scalar_params = described_class.scalar_params

          expect(scalar_params).to include(:wip, :assignee_id)
        end

        context 'filter by deployment' do
          let_it_be(:project_with_repo) { create(:project, :repository) }

          it 'returns the relevant merge requests' do
            deployment1 = create(
              :deployment,
              project: project_with_repo,
              sha: project_with_repo.commit.id,
              merge_requests: [merge_request1, merge_request2]
            )
            create(
              :deployment,
              project: project_with_repo,
              sha: project_with_repo.commit.id,
              merge_requests: [merge_request3]
            )
            params = { deployment_id: deployment1.id }
            merge_requests = described_class.new(user, params).execute

            expect(merge_requests).to contain_exactly(merge_request1, merge_request2)
          end

          context 'when a deployment does not contain any merge requests' do
            it 'returns an empty result' do
              params = { deployment_id: create(:deployment, project: project_with_repo, sha: project_with_repo.commit.sha).id }
              merge_requests = described_class.new(user, params).execute

              expect(merge_requests).to be_empty
            end
          end
        end
      end

      context 'assignee filtering' do
        let(:issuables) { described_class.new(user, params).execute }

        it_behaves_like 'assignee ID filter' do
          let(:params) { { assignee_id: user.id } }
          let(:expected_issuables) { [merge_request1, merge_request2] }
        end

        it_behaves_like 'assignee username filter' do
          before do
            project2.add_developer(user3)
            merge_request3.assignees = [user2, user3]
          end

          set(:user3) { create(:user) }
          let(:params) { { assignee_username: [user2.username, user3.username] } }
          let(:expected_issuables) { [merge_request3] }
        end

        it_behaves_like 'no assignee filter' do
          set(:user3) { create(:user) }
          let(:expected_issuables) { [merge_request4, merge_request5] }
        end

        it_behaves_like 'any assignee filter' do
          let(:expected_issuables) { [merge_request1, merge_request2, merge_request3] }
        end

        context 'filtering by group milestone' do
          let(:group_milestone) { create(:milestone, group: group) }

          before do
            project2.update(namespace: group)
            merge_request2.update(milestone: group_milestone)
            merge_request3.update(milestone: group_milestone)
          end

          it 'returns merge requests assigned to that group milestone' do
            params = { milestone_title: group_milestone.title }

            merge_requests = described_class.new(user, params).execute

            expect(merge_requests).to contain_exactly(merge_request2, merge_request3)
          end
        end
      end

      context 'filtering by created_at/updated_at' do
        let(:new_project) { create(:project, forked_from_project: project1) }

        let!(:new_merge_request) do
          create(:merge_request,
                :simple,
                author: user,
                created_at: 1.week.from_now,
                updated_at: 1.week.from_now,
                source_project: new_project,
                target_project: new_project)
        end

        let!(:old_merge_request) do
          create(:merge_request,
                :simple,
                author: user,
                source_branch: 'feature_1',
                created_at: 1.week.ago,
                updated_at: 1.week.ago,
                source_project: new_project,
                target_project: new_project)
        end

        before do
          new_project.add_maintainer(user)
        end

        it 'filters by created_after' do
          params = { project_id: new_project.id, created_after: new_merge_request.created_at }

          merge_requests = described_class.new(user, params).execute

          expect(merge_requests).to contain_exactly(new_merge_request)
        end

        it 'filters by created_before' do
          params = { project_id: new_project.id, created_before: old_merge_request.created_at }

          merge_requests = described_class.new(user, params).execute

          expect(merge_requests).to contain_exactly(old_merge_request)
        end

        it 'filters by created_after and created_before' do
          params = {
            project_id: new_project.id,
            created_after: old_merge_request.created_at,
            created_before: new_merge_request.created_at
          }

          merge_requests = described_class.new(user, params).execute

          expect(merge_requests).to contain_exactly(old_merge_request, new_merge_request)
        end

        it 'filters by updated_after' do
          params = { project_id: new_project.id, updated_after: new_merge_request.updated_at }

          merge_requests = described_class.new(user, params).execute

          expect(merge_requests).to contain_exactly(new_merge_request)
        end

        it 'filters by updated_before' do
          params = { project_id: new_project.id, updated_before: old_merge_request.updated_at }

          merge_requests = described_class.new(user, params).execute

          expect(merge_requests).to contain_exactly(old_merge_request)
        end

        it 'filters by updated_after and updated_before' do
          params = {
            project_id: new_project.id,
            updated_after: old_merge_request.updated_at,
            updated_before: new_merge_request.updated_at
          }

          merge_requests = described_class.new(user, params).execute

          expect(merge_requests).to contain_exactly(old_merge_request, new_merge_request)
        end
      end
    end

    describe '#row_count', :request_store do
      it 'returns the number of rows for the default state' do
        finder = described_class.new(user)

        expect(finder.row_count).to eq(3)
      end

      it 'returns the number of rows for a given state' do
        finder = described_class.new(user, state: 'closed')

        expect(finder.row_count).to eq(1)
      end
    end

    context 'external authorization' do
      it_behaves_like 'a finder with external authorization service' do
        let!(:subject) { create(:merge_request, source_project: project) }
        let(:project_params) { { project_id: project.id } }
      end
    end
  end

  context 'when projects require different access levels for merge requests' do
    let(:user) { create(:user) }

    let(:public_project) { create(:project, :public) }
    let(:internal) { create(:project, :internal) }
    let(:private_project) { create(:project, :private) }
    let(:public_with_private_repo) { create(:project, :public, :repository, :repository_private) }
    let(:internal_with_private_repo) { create(:project, :internal, :repository, :repository_private) }

    let(:merge_requests) { described_class.new(user, {}).execute }

    let!(:mr_public) { create(:merge_request, source_project: public_project) }
    let!(:mr_private) { create(:merge_request, source_project: private_project) }
    let!(:mr_internal) { create(:merge_request, source_project: internal) }
    let!(:mr_private_repo_access) { create(:merge_request, source_project: public_with_private_repo) }
    let!(:mr_internal_private_repo_access) { create(:merge_request, source_project: internal_with_private_repo) }

    context 'with admin user' do
      let(:user) { create(:user, :admin) }

      it 'returns all merge requests' do
        expect(merge_requests).to eq(
          [mr_internal_private_repo_access, mr_private_repo_access, mr_internal, mr_private, mr_public]
        )
      end
    end

    context 'when project restricts merge requests' do
      let(:non_member) { create(:user) }
      let(:project) { create(:project, :repository, :public, :merge_requests_private) }
      let!(:merge_request) { create(:merge_request, source_project: project) }

      it "returns nothing to to non members" do
        merge_requests = described_class.new(
          non_member,
          project_id: project.id
        ).execute

        expect(merge_requests).to be_empty
      end
    end

    context 'with external user' do
      let(:user) { create(:user, :external) }

      it 'returns only public merge requests' do
        expect(merge_requests).to eq([mr_public])
      end
    end

    context 'with authenticated user' do
      it 'returns public and internal merge requests' do
        expect(merge_requests).to eq([mr_internal, mr_public])
      end

      context 'being added to the private project' do
        context 'as a guest' do
          before do
            private_project.add_guest(user)
          end

          it 'does not return merge requests from the private project' do
            expect(merge_requests).to eq([mr_internal, mr_public])
          end
        end

        context 'as a developer' do
          before do
            private_project.add_developer(user)
          end

          it 'returns merge requests from the private project' do
            expect(merge_requests).to eq([mr_internal, mr_private, mr_public])
          end
        end
      end

      context 'being added to the public project with private repo access' do
        context 'as a guest' do
          before do
            public_with_private_repo.add_guest(user)
          end

          it 'returns merge requests from the project' do
            expect(merge_requests).to eq([mr_internal, mr_public])
          end
        end

        context 'as a reporter' do
          before do
            public_with_private_repo.add_reporter(user)
          end

          it 'returns merge requests from the project' do
            expect(merge_requests).to eq([mr_private_repo_access, mr_internal, mr_public])
          end
        end
      end

      context 'being added to the internal project with private repo access' do
        context 'as a guest' do
          before do
            internal_with_private_repo.add_guest(user)
          end

          it 'returns merge requests from the project' do
            expect(merge_requests).to eq([mr_internal, mr_public])
          end
        end

        context 'as a reporter' do
          before do
            internal_with_private_repo.add_reporter(user)
          end

          it 'returns merge requests from the project' do
            expect(merge_requests).to eq([mr_internal_private_repo_access, mr_internal, mr_public])
          end
        end
      end
    end
  end
end
