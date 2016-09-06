require 'spec_helper'

describe TagsFinder do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:repository) { project.repository }

  describe '#execute' do
    context 'sort only' do
      it 'sorts by name' do
        tags_finder = described_class.new(repository, {})

        result = tags_finder.execute

        expect(result.first.name).to eq("v1.0.0")
      end

      it 'sorts by recently_updated' do
        tags_finder = described_class.new(repository, { sort: 'updated_desc' })

        result = tags_finder.execute
        recently_updated_tag = repository.tags.max do |a, b|
          repository.commit(a.target).committed_date <=> repository.commit(b.target).committed_date
        end

        expect(result.first.name).to eq(recently_updated_tag.name)
      end

      it 'sorts by last_updated' do
        tags_finder = described_class.new(repository, { sort: 'updated_asc' })

        result = tags_finder.execute

        expect(result.first.name).to eq('v1.0.0')
      end
    end

    context 'filter only' do
      it 'filters tags by name' do
        tags_finder = described_class.new(repository, { search: '1.0.0' })

        result = tags_finder.execute

        expect(result.first.name).to eq('v1.0.0')
        expect(result.count).to eq(1)
      end

      it 'does not find any tags with that name' do
        tags_finder = described_class.new(repository, { search: 'hey' })

        result = tags_finder.execute

        expect(result.count).to eq(0)
      end
    end

    context 'filter and sort' do
      it 'filters tags by name and sorts by recently_updated' do
        params = { sort: 'updated_desc', search: 'v1' }
        tags_finder = described_class.new(repository, params)

        result = tags_finder.execute

        expect(result.first.name).to eq('v1.1.0')
        expect(result.count).to eq(2)
      end

      it 'filters tags by name and sorts by last_updated' do
        params = { sort: 'updated_asc', search: 'v1' }
        tags_finder = described_class.new(repository, params)

        result = tags_finder.execute

        expect(result.first.name).to eq('v1.0.0')
        expect(result.count).to eq(2)
      end
    end
  end
end
