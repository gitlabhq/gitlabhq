require 'spec_helper'

describe MergeRequestsFinder do
  include ProjectForksHelper

  # We need to explicitly permit Gitaly N+1s because of the specs that use
  # :request_store. Gitaly N+1 detection is only enabled when :request_store is,
  # but we don't care about potential N+1s when we're just creating several
  # projects in the setup phase.
  def create_project_without_n_plus_1(*args)
    Gitlab::GitalyClient.allow_n_plus_1_calls do
      create(:project, :public, *args)
    end
  end

  context "multiple projects with merge requests" do
    let(:user)  { create :user }
    let(:user2) { create :user }

    let(:group) { create(:group) }
    let(:subgroup) { create(:group, parent: group) }
    let(:project1) { create_project_without_n_plus_1(group: group) }
    let(:project2) do
      Gitlab::GitalyClient.allow_n_plus_1_calls do
        fork_project(project1, user)
      end
    end
    let(:project3) do
      Gitlab::GitalyClient.allow_n_plus_1_calls do
        p = fork_project(project1, user)
        p.update!(archived: true)
        p
      end
    end
    let(:project4) { create_project_without_n_plus_1(:repository, group: subgroup) }
    let(:project5) { create_project_without_n_plus_1(group: subgroup) }
    let(:project6) { create_project_without_n_plus_1(group: subgroup) }

    let!(:merge_request1) { create(:merge_request, author: user, source_project: project2, target_project: project1, target_branch: 'merged-target') }
    let!(:merge_request2) { create(:merge_request, :conflict, author: user, source_project: project2, target_project: project1, state: 'closed') }
    let!(:merge_request3) { create(:merge_request, :simple, author: user, source_project: project2, target_project: project2, state: 'locked', title: 'thing WIP thing') }
    let!(:merge_request4) { create(:merge_request, :simple, author: user, source_project: project3, target_project: project3, title: 'WIP thing') }
    let!(:merge_request5) { create(:merge_request, :simple, author: user, source_project: project4, target_project: project4, title: '[WIP]') }
    let!(:merge_request6) { create(:merge_request, :simple, author: user, source_project: project5, target_project: project5, title: 'WIP: thing') }
    let!(:merge_request7) { create(:merge_request, :simple, author: user, source_project: project6, target_project: project6, title: 'wip thing') }
    let!(:merge_request8) { create(:merge_request, :simple, author: user, source_project: project1, target_project: project1, title: '[wip] thing') }
    let!(:merge_request9) { create(:merge_request, :simple, author: user, source_project: project1, target_project: project2, title: 'wip: thing') }

    before do
      project1.add_maintainer(user)
      project2.add_developer(user)
      project3.add_developer(user)
      project2.add_developer(user2)
      project4.add_developer(user)
      project5.add_developer(user)
      project6.add_developer(user)
    end

    describe '#execute' do
      it 'filters by scope' do
        params = { scope: 'authored', state: 'opened' }
        merge_requests = described_class.new(user, params).execute
        expect(merge_requests.size).to eq(7)
      end

      it 'filters by project' do
        params = { project_id: project1.id, scope: 'authored', state: 'opened' }
        merge_requests = described_class.new(user, params).execute
        expect(merge_requests.size).to eq(2)
      end

      it 'filters by commit sha' do
        merge_requests = described_class.new(
          user,
          commit_sha: merge_request5.merge_request_diff.last_commit_sha
        ).execute

        expect(merge_requests).to contain_exactly(merge_request5)
      end

      context 'filtering by group' do
        it 'includes all merge requests when user has access' do
          params = { group_id: group.id }

          merge_requests = described_class.new(user, params).execute

          expect(merge_requests.size).to eq(3)
        end

        it 'excludes merge requests from projects the user does not have access to' do
          private_project = create_project_without_n_plus_1(:private, group: group)
          private_mr = create(:merge_request, :simple, author: user, source_project: private_project, target_project: private_project)
          params = { group_id: group.id }

          private_project.add_guest(user)
          merge_requests = described_class.new(user, params).execute

          expect(merge_requests.size).to eq(3)
          expect(merge_requests).not_to include(private_mr)
        end

        it 'filters by group including subgroups', :nested_groups do
          params = { group_id: group.id, include_subgroups: true }

          merge_requests = described_class.new(user, params).execute

          expect(merge_requests.size).to eq(6)
        end
      end

      it 'filters by non_archived' do
        params = { non_archived: true }
        merge_requests = described_class.new(user, params).execute
        expect(merge_requests.size).to eq(8)
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

      it 'filters by state' do
        params = { state: 'locked' }

        merge_requests = described_class.new(user, params).execute

        expect(merge_requests).to contain_exactly(merge_request3)
      end

      it 'filters by wip' do
        params = { wip: 'yes' }

        merge_requests = described_class.new(user, params).execute

        expect(merge_requests).to contain_exactly(merge_request4, merge_request5, merge_request6, merge_request7, merge_request8, merge_request9)
      end

      it 'filters by not wip' do
        params = { wip: 'no' }

        merge_requests = described_class.new(user, params).execute

        expect(merge_requests).to contain_exactly(merge_request1, merge_request2, merge_request3)
      end

      it 'returns all items if no valid wip param exists' do
        params = { wip: '' }

        merge_requests = described_class.new(user, params).execute

        expect(merge_requests).to contain_exactly(merge_request1, merge_request2, merge_request3, merge_request4, merge_request5, merge_request6, merge_request7, merge_request8, merge_request9)
      end

      it 'adds wip to scalar params' do
        scalar_params = described_class.scalar_params

        expect(scalar_params).to include(:wip, :assignee_id)
      end

      context 'filtering by group milestone' do
        let!(:group) { create(:group, :public) }
        let(:group_milestone) { create(:milestone, group: group) }
        let!(:group_member) { create(:group_member, group: group, user: user) }
        let(:params) { { milestone_title: group_milestone.title } }

        before do
          project2.update(namespace: group)
          merge_request2.update(milestone: group_milestone)
          merge_request3.update(milestone: group_milestone)
        end

        it 'returns issues assigned to that group milestone' do
          merge_requests = described_class.new(user, params).execute

          expect(merge_requests).to contain_exactly(merge_request2, merge_request3)
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

        expect(finder.row_count).to eq(7)
      end

      it 'returns the number of rows for a given state' do
        finder = described_class.new(user, state: 'closed')

        expect(finder.row_count).to eq(1)
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
