# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::MergeRequests::Accept, feature_category: :api do
  include GraphqlHelpers
  include AfterNextHelpers

  let_it_be(:user) { create(:user) }
  let(:project) { create(:project, :public, :repository) }
  let(:query) { GraphQL::Query.new(empty_schema, document: nil, context: {}, variables: {}) }
  let(:context) { GraphQL::Query::Context.new(query: query, values: { current_user: user }) }

  subject(:mutation) { described_class.new(context: context, object: nil, field: nil) }

  before do
    project.repository.expire_all_method_caches
  end

  describe '#resolve' do
    before do
      project.add_maintainer(user)
    end

    let(:common_args) do
      {
        project_path: project.full_path,
        iid: merge_request.iid.to_s,
        sha: merge_request.diff_head_sha,
        squash: false # default value
      }
    end

    let(:args) { common_args.merge(additional_args) }
    let(:additional_args) { {} }
    let(:result) { mutation.resolve(**args) }
    let!(:merge_request) { create(:merge_request, source_project: project) }

    it 'merges the merge request asynchronously' do
      expect_next_found_instance_of(MergeRequest) do |instance|
        expect(instance).to receive(:merge_async).with(user.id, args.except(:project_path, :iid))
      end
      expect(result).to include(errors: be_empty)
    end

    context 'when the squash flag is specified' do
      let(:additional_args) { { squash: true } }

      it 'sets squash on the merge request' do
        expect { result }.to change { merge_request.reload.squash }.from(false).to(true)
      end
    end

    context 'when the sha is a mismatch' do
      let(:additional_args) { { sha: 'not a good sha' } }

      it 'rejects the mutation' do
        expect_next_found_instance_of(MergeRequest) do |instance|
          expect(instance).not_to receive(:merge_async)
        end
        expect(result).to include(errors: [described_class::SHA_MISMATCH])
      end
    end

    context 'when MR is unmergeable' do
      let(:merge_request) { create(:merge_request, :closed, source_project: project) }

      it 'rejects the MRs' do
        expect_next_found_instance_of(MergeRequest) do |instance|
          expect(instance).not_to receive(:merge_async)
        end
        expect(result).to include(errors: [described_class::NOT_MERGEABLE])
      end
    end

    it 'rejects merges when we cannot validate the hooks' do
      expect_next(::MergeRequests::MergeService)
        .to receive(:hooks_validation_pass?).with(merge_request).and_return(false)

      expect_next_found_instance_of(MergeRequest) do |instance|
        expect(instance).not_to receive(:merge_async)
      end
      expect(result).to include(errors: [described_class::HOOKS_VALIDATION_ERROR])
    end

    context 'when MR has head pipeline' do
      let(:merge_request) { create(:merge_request, :with_head_pipeline, source_project: project) }
      let(:strategy) { ::Types::MergeStrategyEnum.values['MERGE_WHEN_CHECKS_PASS'].value }
      let(:additional_args) { { auto_merge_strategy: strategy } }

      it "can use the MERGE_WHEN_CHECKS_PASS strategy" do
        expect_next_found_instance_of(MergeRequest) do |instance|
          expect(instance).not_to receive(:merge_async)
        end
        expect(result).to include(errors: be_empty, merge_request: be_auto_merge_enabled)
      end

      context 'when MR is in draft state' do
        before do
          merge_request.update!(title: "Draft: Test")
        end

        it "can use the MERGE_WHEN_CHECKS_PASS strategy" do
          expect_next_found_instance_of(MergeRequest) do |instance|
            expect(instance).not_to receive(:merge_async)
          end
          expect(result).to include(errors: be_empty, merge_request: be_auto_merge_enabled)
        end
      end
    end
  end
end
