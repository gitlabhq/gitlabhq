# frozen_string_literal: true

require 'spec_helper'

describe BranchesFinder do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }

  describe '#execute' do
    context 'sort only' do
      it 'sorts by name' do
        branches_finder = described_class.new(repository, {})

        result = branches_finder.execute

        expect(result.first.name).to eq("'test'")
      end

      it 'sorts by recently_updated' do
        branches_finder = described_class.new(repository, { sort: 'updated_desc' })

        result = branches_finder.execute

        recently_updated_branch = repository.branches.max do |a, b|
          repository.commit(a.dereferenced_target).committed_date <=> repository.commit(b.dereferenced_target).committed_date
        end

        expect(result.first.name).to eq(recently_updated_branch.name)
      end

      it 'sorts by last_updated' do
        branches_finder = described_class.new(repository, { sort: 'updated_asc' })

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

      it 'filters branches by name ignoring letter case' do
        branches_finder = described_class.new(repository, { search: 'FiX' })

        result = branches_finder.execute

        expect(result.first.name).to eq('fix')
        expect(result.count).to eq(1)
      end

      it 'does not find any branch with that name' do
        branches_finder = described_class.new(repository, { search: 'random' })

        result = branches_finder.execute

        expect(result.count).to eq(0)
      end

      it 'filters branches by provided names' do
        branches_finder = described_class.new(repository, { names: ['fix', 'csv', 'lfs', 'does-not-exist'] })

        result = branches_finder.execute

        expect(result.count).to eq(3)
        expect(result.map(&:name)).to eq(%w{csv fix lfs})
      end

      it 'filters branches by name that begins with' do
        params = { search: '^feature_' }
        branches_finder = described_class.new(repository, params)

        result = branches_finder.execute

        expect(result.first.name).to eq('feature_conflict')
        expect(result.count).to eq(1)
      end

      it 'filters branches by name that ends with' do
        params = { search: 'feature$' }
        branches_finder = described_class.new(repository, params)

        result = branches_finder.execute

        expect(result.first.name).to eq('feature')
        expect(result.count).to eq(1)
      end

      it 'filters branches by nonexistent name that begins with' do
        params = { search: '^nope' }
        branches_finder = described_class.new(repository, params)

        result = branches_finder.execute

        expect(result.count).to eq(0)
      end

      it 'filters branches by nonexistent name that ends with' do
        params = { search: 'nope$' }
        branches_finder = described_class.new(repository, params)

        result = branches_finder.execute

        expect(result.count).to eq(0)
      end
    end

    context 'filter and sort' do
      it 'filters branches by name and sorts by recently_updated' do
        params = { sort: 'updated_desc', search: 'feat' }
        branches_finder = described_class.new(repository, params)

        result = branches_finder.execute

        expect(result.first.name).to eq('feature_conflict')
        expect(result.count).to eq(2)
      end

      it 'filters branches by name and sorts by recently_updated, with exact matches first' do
        params = { sort: 'updated_desc', search: 'feature' }
        branches_finder = described_class.new(repository, params)

        result = branches_finder.execute

        expect(result.first.name).to eq('feature')
        expect(result.second.name).to eq('feature_conflict')
        expect(result.count).to eq(2)
      end

      it 'filters branches by name and sorts by last_updated' do
        params = { sort: 'updated_asc', search: 'feature' }
        branches_finder = described_class.new(repository, params)

        result = branches_finder.execute

        expect(result.first.name).to eq('feature')
        expect(result.count).to eq(2)
      end
    end
  end
end
