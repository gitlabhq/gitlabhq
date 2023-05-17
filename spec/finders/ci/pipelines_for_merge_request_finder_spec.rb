# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelinesForMergeRequestFinder do
  describe '#execute' do
    include ProjectForksHelper

    subject { finder.execute }

    let_it_be(:developer_in_parent) { create(:user) }
    let_it_be(:developer_in_fork) { create(:user) }
    let_it_be(:developer_in_both) { create(:user) }
    let_it_be(:reporter_in_parent_and_developer_in_fork) { create(:user) }
    let_it_be(:external_user) { create(:user) }
    let_it_be(:parent_project) { create(:project, :repository, :private) }
    let_it_be(:forked_project) { fork_project(parent_project, nil, repository: true, target_project: create(:project, :private, :repository)) }

    let(:merge_request) do
      create(
        :merge_request, source_project: forked_project, source_branch: 'feature',
        target_project: parent_project, target_branch: 'master'
      )
    end

    let!(:pipeline_in_parent) do
      create(:ci_pipeline, :merged_result_pipeline, merge_request: merge_request, project: parent_project)
    end

    let!(:pipeline_in_fork) do
      create(:ci_pipeline, :merged_result_pipeline, merge_request: merge_request, project: forked_project)
    end

    let(:finder) { described_class.new(merge_request, actor) }

    before_all do
      parent_project.add_developer(developer_in_parent)
      parent_project.add_developer(developer_in_both)
      parent_project.add_reporter(reporter_in_parent_and_developer_in_fork)
      forked_project.add_developer(developer_in_fork)
      forked_project.add_developer(developer_in_both)
      forked_project.add_developer(reporter_in_parent_and_developer_in_fork)
    end

    context 'when actor has permission to read pipelines in both parent and forked projects' do
      let(:actor) { developer_in_both }

      it 'returns all pipelines' do
        is_expected.to match_array([pipeline_in_fork, pipeline_in_parent])
      end
    end

    context 'when actor has permission to read pipelines in both parent and forked projects' do
      let(:actor) { reporter_in_parent_and_developer_in_fork }

      it 'returns all pipelines' do
        is_expected.to match_array([pipeline_in_fork, pipeline_in_parent])
      end
    end

    context 'when actor has permission to read pipelines in the parent project only' do
      let(:actor) { developer_in_parent }

      it 'returns pipelines in parent' do
        is_expected.to match_array([pipeline_in_parent])
      end
    end

    context 'when actor has permission to read pipelines in the forked project only' do
      let(:actor) { developer_in_fork }

      it 'returns pipelines in fork' do
        is_expected.to match_array([pipeline_in_fork])
      end
    end

    context 'when actor does not have permission to read pipelines' do
      let(:actor) { external_user }

      it 'returns nothing' do
        is_expected.to be_empty
      end
    end

    context 'when actor is nil' do
      let(:actor) { nil }

      it 'returns nothing' do
        is_expected.to be_empty
      end
    end
  end

  describe '#all' do
    let(:merge_request) { create(:merge_request) }
    let(:project) { merge_request.source_project }

    subject { described_class.new(merge_request, nil) }

    shared_examples 'returning pipelines with proper ordering' do
      let!(:all_pipelines) do
        merge_request.recent_diff_head_shas.map do |sha|
          create(:ci_empty_pipeline,
            project: project, sha: sha, ref: merge_request.source_branch)
        end
      end

      it 'returns all pipelines' do
        expect(subject.all).not_to be_empty
        expect(subject.all).to eq(all_pipelines.reverse)
      end
    end

    context 'with single merge_request_diffs' do
      it_behaves_like 'returning pipelines with proper ordering'
    end

    context 'with multiple irrelevant merge_request_diffs' do
      before do
        merge_request.update!(target_branch: 'v1.0.0')
      end

      it_behaves_like 'returning pipelines with proper ordering'
    end

    context 'with unsaved merge request' do
      let(:merge_request) { build(:merge_request, source_project: create(:project, :repository)) }

      let!(:pipeline) do
        create(
          :ci_empty_pipeline, project: project,
          sha: merge_request.diff_head_sha, ref: merge_request.source_branch
        )
      end

      it 'returns pipelines from diff_head_sha' do
        expect(subject.all).to contain_exactly(pipeline)
      end
    end

    context 'when pipelines exist for the branch and merge request' do
      let(:source_ref) { 'feature' }
      let(:target_ref) { 'master' }

      let!(:branch_pipeline) do
        create(
          :ci_pipeline, source: :push, project: project,
          ref: source_ref, sha: merge_request.merge_request_diff.head_commit_sha
        )
      end

      let!(:tag_pipeline) do
        create(:ci_pipeline, project: project, ref: source_ref, tag: true)
      end

      let!(:detached_merge_request_pipeline) do
        create(
          :ci_pipeline, source: :merge_request_event, project: project,
          ref: source_ref, sha: shas.second, merge_request: merge_request
        )
      end

      let(:merge_request) do
        create(
          :merge_request, source_project: project, source_branch: source_ref,
          target_project: project, target_branch: target_ref
        )
      end

      let(:project) { create(:project, :repository) }
      let(:shas) { project.repository.commits(source_ref, limit: 2).map(&:id) }

      it 'returns merge request pipeline first' do
        expect(subject.all).to match_array([detached_merge_request_pipeline, branch_pipeline])
      end

      context 'when there are a branch pipeline and a merge request pipeline' do
        let!(:branch_pipeline_2) do
          create(:ci_pipeline, source: :push, project: project, ref: source_ref, sha: shas.first)
        end

        let!(:detached_merge_request_pipeline_2) do
          create(
            :ci_pipeline, source: :merge_request_event, project: project,
            ref: source_ref, sha: shas.first, merge_request: merge_request
          )
        end

        it 'returns merge request pipelines first' do
          expect(subject.all)
            .to match_array([detached_merge_request_pipeline_2, detached_merge_request_pipeline, branch_pipeline_2, branch_pipeline])
        end
      end

      context 'when there are multiple merge request pipelines from the same branch' do
        let!(:branch_pipeline_2) do
          create(:ci_pipeline, source: :push, project: project, ref: source_ref, sha: shas.first)
        end

        let!(:branch_pipeline_with_sha_not_belonging_to_merge_request) do
          create(:ci_pipeline, source: :push, project: project, ref: source_ref)
        end

        let!(:detached_merge_request_pipeline_2) do
          create(
            :ci_pipeline, source: :merge_request_event, project: project,
            ref: source_ref, sha: shas.first, merge_request: merge_request_2
          )
        end

        let(:merge_request_2) do
          create(
            :merge_request, source_project: project, source_branch: source_ref,
            target_project: project, target_branch: 'stable'
          )
        end

        before do
          shas.each.with_index do |sha, index|
            create(
              :merge_request_diff_commit,
              merge_request_diff: merge_request_2.merge_request_diff,
              sha: sha, relative_order: index
            )
          end
        end

        it 'returns only related merge request pipelines' do
          expect(subject.all).to match_array([detached_merge_request_pipeline, branch_pipeline_2, branch_pipeline])

          expect(described_class.new(merge_request_2, nil).all)
            .to match_array([detached_merge_request_pipeline_2, branch_pipeline_2, branch_pipeline])
        end
      end

      context 'when detached merge request pipeline is run on head ref of the merge request' do
        let!(:detached_merge_request_pipeline) do
          create(
            :ci_pipeline, source: :merge_request_event, project: project,
            ref: merge_request.ref_path, sha: shas.second, merge_request: merge_request
          )
        end

        it 'sets the head ref of the merge request to the pipeline ref' do
          expect(detached_merge_request_pipeline.ref).to match(%r{refs/merge-requests/\d+/head})
        end

        it 'includes the detached merge request pipeline even though the ref is custom path' do
          expect(merge_request.all_pipelines).to include(detached_merge_request_pipeline)
        end
      end
    end
  end
end
