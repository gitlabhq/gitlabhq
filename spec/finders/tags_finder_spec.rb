require 'spec_helper'

describe TagsFinder do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
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
          repository.commit(a.dereferenced_target).committed_date <=> repository.commit(b.dereferenced_target).committed_date
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
      let(:tags_to_compare) { %w[v1.0.0 v1.1.0] }
      subject { described_class.new(repository, params).execute.select { |tag| tags_to_compare.include?(tag.name) } }

      context 'when sort by updated_desc' do
        let(:params) { { sort: 'updated_desc', search: 'v1' } }

        it 'filters tags by name' do
          expect(subject.first.name).to eq('v1.1.0')
          expect(subject.count).to eq(2)
        end
      end

      context 'when sort by updated_asc' do
        let(:params) { { sort: 'updated_asc', search: 'v1' } }

        it 'filters tags by name' do
          expect(subject.first.name).to eq('v1.0.0')
          expect(subject.count).to eq(2)
        end
      end
    end
  end
end
