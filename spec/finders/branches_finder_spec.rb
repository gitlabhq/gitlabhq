require 'spec_helper'

describe BranchesFinder do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:repository) { project.repository }

  describe '#execute' do
    context 'sort only' do
      it 'sorts by name' do
        branches_finder = described_class.new(repository, {})

        result = branches_finder.execute

        expect(result.first.name).to eq("'test'")
      end

      it 'sorts by recently_updated' do
        branches_finder = described_class.new(repository, { sort: 'recently_updated' })

        result = branches_finder.execute

        expect(result.first.name).to eq('crlf-diff')
      end

      it 'sorts by last_updated' do
        branches_finder = described_class.new(repository, { sort: 'last_updated' })

        result = branches_finder.execute

        expect(result.first.name).to eq('feature')
      end
    end

    context 'filter only' do
      it 'filters branches by name' do
        branches_finder = described_class.new(repository, { search: 'fix' })

        result = branches_finder.execute

        expect(result.first.name).to eq('fix')
        expect(result.count).to eq(1)
      end

      it 'does not find any branch with that name' do
        branches_finder = described_class.new(repository, { search: 'random' })

        result = branches_finder.execute

        expect(result.count).to eq(0)
      end
    end

    context 'filter and sort' do
      it 'filters branches by name and sorts by recently_updated' do
        params = { sort: 'recently_updated', search: 'feature' }
        branches_finder = described_class.new(repository, params)

        result = branches_finder.execute

        expect(result.first.name).to eq('feature_conflict')
        expect(result.count).to eq(2)
      end

      it 'filters branches by name and sorts by last_updated' do
        params = { sort: 'last_updated', search: 'feature' }
        branches_finder = described_class.new(repository, params)

        result = branches_finder.execute

        expect(result.first.name).to eq('feature')
        expect(result.count).to eq(2)
      end
    end
  end
end
