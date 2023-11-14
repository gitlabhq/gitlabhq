# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Catalog::Resources::VersionsFinder, feature_category: :pipeline_composition do
  include_context 'when there are catalog resources with versions'

  let(:sort) { nil }
  let(:latest) { nil }
  let(:params) { { sort: sort, latest: latest }.compact }

  subject(:execute) { described_class.new([resource1, resource2], current_user, params).execute }

  it 'avoids N+1 queries when authorizing multiple catalog resources', :request_store do
    control_count = ActiveRecord::QueryRecorder.new { execute }

    # A new user is required to avoid a false positive from cached user authorization queries
    new_user = create(:user)

    expect do
      described_class.new([resource1, resource2, resource3], new_user, params).execute
    end.not_to exceed_query_limit(control_count)
  end

  context 'when the user is not authorized for any catalog resource' do
    it 'returns empty response' do
      is_expected.to be_empty
    end
  end

  describe 'versions' do
    before_all do
      resource1.project.add_guest(current_user)
    end

    it 'returns the versions of the authorized catalog resource' do
      expect(execute).to match_array([v1_0, v1_1])
    end

    context 'with sort parameter' do
      it 'returns versions ordered by released_at descending by default' do
        expect(execute).to eq([v1_1, v1_0])
      end

      context 'when sort is released_at_asc' do
        let(:sort) { 'released_at_asc' }

        it 'returns versions ordered by released_at ascending' do
          expect(execute).to eq([v1_0, v1_1])
        end
      end

      context 'when sort is created_asc' do
        let(:sort) { 'created_asc' }

        it 'returns versions ordered by created_at ascending' do
          expect(execute).to eq([v1_1, v1_0])
        end
      end

      context 'when sort is created_desc' do
        let(:sort) { 'created_desc' }

        it 'returns versions ordered by created_at descending' do
          expect(execute).to eq([v1_0, v1_1])
        end
      end
    end

    it 'preloads associations' do
      expect(Ci::Catalog::Resources::Version).to receive(:preloaded).once.and_call_original

      execute
    end
  end

  describe 'latest versions' do
    before_all do
      resource1.project.add_guest(current_user)
      resource2.project.add_guest(current_user)
    end

    let(:latest) { true }

    it 'returns the latest version for each authorized catalog resource' do
      expect(execute).to match_array([v1_1, v2_1])
    end

    context 'when one catalog resource does not have versions' do
      it 'returns the latest version of only the catalog resource with versions' do
        resource1.versions.delete_all(:delete_all)

        is_expected.to match_array([v2_1])
      end
    end

    context 'when no catalog resource has versions' do
      it 'returns empty response' do
        resource1.versions.delete_all(:delete_all)
        resource2.versions.delete_all(:delete_all)

        is_expected.to be_empty
      end
    end
  end
end
