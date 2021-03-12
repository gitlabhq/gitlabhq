# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::MergeRequests::Accept do
  include AfterNextHelpers

  let_it_be(:user) { create(:user) }
  let(:project) { create(:project, :public, :repository) }

  subject(:mutation) { described_class.new(context: context, object: nil, field: nil) }

  let_it_be(:context) do
    GraphQL::Query::Context.new(
      query: OpenStruct.new(schema: GitlabSchema),
      values: { current_user: user },
      object: nil
    )
  end

  before do
    project.repository.expire_all_method_caches
  end

  describe '#resolve' do
    before do
      project.add_maintainer(user)
    end

    def common_args(merge_request)
      {
        project_path: project.full_path,
        iid: merge_request.iid.to_s,
        sha: merge_request.diff_head_sha,
        squash: false # default value
      }
    end

    it 'merges the merge request' do
      merge_request = create(:merge_request, source_project: project)

      result = mutation.resolve(**common_args(merge_request))

      expect(result).to include(errors: be_empty, merge_request: be_merged)
    end

    it 'rejects the mutation if the SHA is a mismatch' do
      merge_request = create(:merge_request, source_project: project)
      args = common_args(merge_request).merge(sha: 'not a good sha')

      result = mutation.resolve(**args)

      expect(result).not_to include(merge_request: be_merged)
      expect(result).to include(errors: [described_class::SHA_MISMATCH])
    end

    it 'respects the merge commit message' do
      merge_request = create(:merge_request, source_project: project)
      args = common_args(merge_request).merge(commit_message: 'my super custom message')

      result = mutation.resolve(**args)

      expect(result).to include(merge_request: be_merged)
      expect(project.repository.commit(merge_request.target_branch)).to have_attributes(
        message: args[:commit_message]
      )
    end

    it 'respects the squash flag' do
      merge_request = create(:merge_request, source_project: project)
      args = common_args(merge_request).merge(squash: true)

      result = mutation.resolve(**args)

      expect(result).to include(merge_request: be_merged)
      expect(result[:merge_request].squash_commit_sha).to be_present
    end

    it 'respects the squash_commit_message argument' do
      merge_request = create(:merge_request, source_project: project)
      args = common_args(merge_request).merge(squash: true, squash_commit_message: 'squish')

      result = mutation.resolve(**args)
      sha = result[:merge_request].squash_commit_sha

      expect(result).to include(merge_request: be_merged)
      expect(project.repository.commit(sha)).to have_attributes(message: "squish\n")
    end

    it 'respects the should_remove_source_branch argument when true' do
      b = project.repository.add_branch(user, generate(:branch), 'master')
      merge_request = create(:merge_request, source_branch: b.name, source_project: project)
      args = common_args(merge_request).merge(should_remove_source_branch: true)

      expect(::MergeRequests::DeleteSourceBranchWorker).to receive(:perform_async)

      result = mutation.resolve(**args)

      expect(result).to include(merge_request: be_merged)
    end

    it 'respects the should_remove_source_branch argument when false' do
      b = project.repository.add_branch(user, generate(:branch), 'master')
      merge_request = create(:merge_request, source_branch: b.name, source_project: project)
      args = common_args(merge_request).merge(should_remove_source_branch: false)

      expect(::MergeRequests::DeleteSourceBranchWorker).not_to receive(:perform_async)

      result = mutation.resolve(**args)

      expect(result).to include(merge_request: be_merged)
    end

    it 'rejects unmergeable MRs' do
      merge_request = create(:merge_request, :closed, source_project: project)
      args = common_args(merge_request)

      result = mutation.resolve(**args)

      expect(result).not_to include(merge_request: be_merged)
      expect(result).to include(errors: [described_class::NOT_MERGEABLE])
    end

    it 'rejects merges when we cannot validate the hooks' do
      merge_request = create(:merge_request, source_project: project)
      args = common_args(merge_request)
      expect_next(::MergeRequests::MergeService)
        .to receive(:hooks_validation_pass?).with(merge_request).and_return(false)

      result = mutation.resolve(**args)

      expect(result).not_to include(merge_request: be_merged)
      expect(result).to include(errors: [described_class::HOOKS_VALIDATION_ERROR])
    end

    it 'rejects merges when the merge service returns an error' do
      merge_request = create(:merge_request, source_project: project)
      args = common_args(merge_request)
      expect_next(::MergeRequests::MergeService)
        .to receive(:execute).with(merge_request).and_return(:failed)

      result = mutation.resolve(**args)

      expect(result).not_to include(merge_request: be_merged)
      expect(result).to include(errors: [described_class::MERGE_FAILED])
    end

    it 'rejects merges when the merge service raises merge error' do
      merge_request = create(:merge_request, source_project: project)
      args = common_args(merge_request)
      expect_next(::MergeRequests::MergeService)
        .to receive(:execute).and_raise(::MergeRequests::MergeBaseService::MergeError, 'boom')

      result = mutation.resolve(**args)

      expect(result).not_to include(merge_request: be_merged)
      expect(result).to include(errors: ['boom'])
    end

    it "can use the MERGE_WHEN_PIPELINE_SUCCEEDS strategy" do
      enum = ::Types::MergeStrategyEnum.values['MERGE_WHEN_PIPELINE_SUCCEEDS']
      merge_request = create(:merge_request, :with_head_pipeline, source_project: project)
      args = common_args(merge_request).merge(auto_merge_strategy: enum.value)

      result = mutation.resolve(**args)

      expect(result).not_to include(merge_request: be_merged)
      expect(result).to include(errors: be_empty, merge_request: be_auto_merge_enabled)
    end
  end
end
