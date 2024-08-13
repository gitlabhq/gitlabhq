# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::TagsFinder, feature_category: :runner do
  describe '#execute' do
    let_it_be(:tag1) { create(:ci_tag, name: 'tag1') }
    let_it_be(:tag2) { create(:ci_tag, name: 'tag2') }

    context 'with empty params' do
      it 'returns all tags' do
        tags = described_class.new(params: {}).execute

        expect(tags).to match_array [tag1, tag2]
      end
    end

    context 'with search filters' do
      context 'with an empty search term' do
        it 'returns all tags' do
          tags = described_class.new(params: { search: '' }).execute

          expect(tags).to match_array [tag1, tag2]
        end
      end

      context 'with a search containing 2 characters' do
        it 'returns the tag that strictly matches the search term' do
          t1 = create(:ci_tag, name: 't1')
          create(:ci_tag, name: 't11')

          tags = described_class.new(params: { search: 't1' }).execute

          expect(tags).to match_array [t1]
        end
      end

      context 'with a search containing 3 characters' do
        it 'returns the tag that partially matches the search term' do
          tag11 = create(:ci_tag, name: 'tag11')

          tags = described_class.new(params: { search: 'ag1' }).execute

          expect(tags).to match_array [tag1, tag11]
        end
      end
    end
  end
end
