require 'spec_helper'

describe Resolvers::MergeRequestResolver do
  include GraphqlHelpers

  set(:project) { create(:project, :repository) }
  set(:merge_request_1) { create(:merge_request, :simple, source_project: project, target_project: project) }
  set(:merge_request_2) { create(:merge_request, :rebased, source_project: project, target_project: project) }

  set(:other_project) { create(:project, :repository) }
  set(:other_merge_request) { create(:merge_request, source_project: other_project, target_project: other_project) }

  let(:full_path) { project.full_path }
  let(:iid_1) { merge_request_1.iid }
  let(:iid_2) { merge_request_2.iid }

  let(:other_full_path) { other_project.full_path }
  let(:other_iid) { other_merge_request.iid }

  describe '#resolve' do
    it 'batch-resolves merge requests by target project full path and IID' do
      path = full_path # avoid database query

      result = batch(max_queries: 2) do
        [resolve_mr(path, iid_1), resolve_mr(path, iid_2)]
      end

      expect(result).to contain_exactly(merge_request_1, merge_request_2)
    end

    it 'can batch-resolve merge requests from different projects' do
      path = project.full_path # avoid database queries
      other_path = other_full_path

      result = batch(max_queries: 3) do
        [resolve_mr(path, iid_1), resolve_mr(path, iid_2), resolve_mr(other_path, other_iid)]
      end

      expect(result).to contain_exactly(merge_request_1, merge_request_2, other_merge_request)
    end

    it 'resolves an unknown iid to nil' do
      result = batch { resolve_mr(full_path, -1) }

      expect(result).to be_nil
    end

    it 'resolves a known iid for an unknown full_path to nil' do
      result = batch { resolve_mr('unknown/project', iid_1) }

      expect(result).to be_nil
    end
  end

  def resolve_mr(full_path, iid)
    resolve(described_class, args: { full_path: full_path, iid: iid })
  end
end
