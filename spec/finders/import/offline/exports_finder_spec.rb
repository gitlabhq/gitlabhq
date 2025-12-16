# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::Offline::ExportsFinder, feature_category: :importers do
  let_it_be(:user) { create(:user) }
  let_it_be(:started_export) { create(:offline_export, :started, user: user) }
  let_it_be(:finished_export) { create(:offline_export, :finished, user: user) }
  let_it_be(:other_user_export) { create(:offline_export) }
  let(:params) { {} }

  subject(:finder) { described_class.new(user: user, params: params) }

  describe '#execute' do
    it 'returns all exports for the user in descending order' do
      expect(finder.execute).to contain_exactly(started_export, finished_export)
    end

    context 'when order is specified' do
      context 'when order is asc' do
        let(:params) { { sort: 'asc' } }

        it 'returns exports in ascending order' do
          expect(finder.execute.to_a).to eq([started_export, finished_export])
        end
      end

      context 'when order is desc' do
        let(:params) { { sort: 'desc' } }

        it 'returns exports in descending order' do
          expect(finder.execute.to_a).to eq([finished_export, started_export])
        end
      end
    end

    context 'when status is specified' do
      let(:params) { { status: 'started' } }

      it 'returns only started exports' do
        expect(finder.execute).to contain_exactly(started_export)
      end

      context 'when filtering by invalid status' do
        let(:params) { { status: 'invalid' } }

        it 'does not filter by status' do
          expect(finder.execute).to contain_exactly(started_export, finished_export)
        end
      end
    end
  end
end
