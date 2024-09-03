# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::SourceUsersFinder, feature_category: :importers do
  let_it_be(:user) { build_stubbed(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:source_user_1) { create(:import_source_user, :pending_reassignment, namespace: group, source_name: 'b') }
  let_it_be(:source_user_2) { create(:import_source_user, :awaiting_approval, namespace: group, source_name: 'c') }
  let_it_be(:source_user_3) do
    create(:import_source_user, :reassignment_in_progress, namespace: group, source_name: 'a')
  end

  let_it_be(:import_source_users) { [source_user_1, source_user_2, source_user_3] }

  let(:params) { {} }

  describe '#execute' do
    subject(:source_user_result) { described_class.new(group, user, params).execute }

    context 'when user is not authorized to read the import source users' do
      before do
        stub_member_access_level(group, maintainer: user)
      end

      it { expect(source_user_result).to be_empty }
    end

    context 'when user is authorized to read the import source users' do
      before do
        stub_member_access_level(group, owner: user)
      end

      it 'returns all import source users' do
        expect(source_user_result).to match_array(import_source_users)
      end

      describe 'filtering by statuses' do
        context 'when statuses are not provided' do
          let(:params) { {} }

          it 'returns all import source users' do
            expect(source_user_result).to match_array(import_source_users)
          end
        end

        context 'when statuses are is provided' do
          let(:params) { { statuses: [0, 1] } }

          it 'returns import source users with the corresponding status' do
            expect(source_user_result.pluck(:status)).to match_array([0, 1])
          end
        end
      end

      describe 'filtering by search' do
        context 'when search are not provided' do
          let(:params) { {} }

          it 'returns all import source users' do
            expect(source_user_result).to match_array(import_source_users)
          end
        end

        context 'when search is is provided' do
          let(:params) { { search: 'b' } }

          it 'returns import source users with matches the search query' do
            expect(source_user_result).to match_array([source_user_1])
          end
        end
      end

      describe 'sorting' do
        let(:params) { { sort: 'source_name_desc' } }

        it 'returns import source users sorted by the provided method' do
          expect(source_user_result.pluck(:source_name)).to eq(%w[c b a])
        end

        context 'when sort is not provided' do
          let(:params) { {} }

          it 'returns import source users sorted by source_name_asc' do
            expect(source_user_result.pluck(:source_name)).to eq(%w[a b c])
          end
        end
      end
    end
  end
end
