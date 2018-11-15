# frozen_string_literal: true

require 'spec_helper'

describe Autocomplete::ActsAsTaggableOn::TagsFinder do
  describe '#execute' do
    context 'with empty params' do
      it 'returns all tags' do
        create :ci_runner, tag_list: ['tag1']
        create :ci_runner, tag_list: ['tag2']

        tags = described_class.new(taggable_type: Ci::Runner, params: {}).execute.map(&:name)

        expect(tags).to match_array %w(tag1 tag2)
      end
    end

    context 'filter by search' do
      context 'with an empty search term' do
        it 'returns an empty collection' do
          create :ci_runner, tag_list: ['tag1']
          create :ci_runner, tag_list: ['tag2']

          tags = described_class.new(taggable_type: Ci::Runner, params: { search: '' }).execute.map(&:name)

          expect(tags).to be_empty
        end
      end

      context 'with a search containing 2 characters' do
        it 'returns the tag that strictly matches the search term' do
          create :ci_runner, tag_list: ['t1']
          create :ci_runner, tag_list: ['t11']

          tags = described_class.new(taggable_type: Ci::Runner, params: { search: 't1' }).execute.map(&:name)

          expect(tags).to match_array ['t1']
        end
      end

      context 'with a search containing 3 characters' do
        it 'returns the tag that partially matches the search term' do
          create :ci_runner, tag_list: ['tag1']
          create :ci_runner, tag_list: ['tag11']

          tags = described_class.new(taggable_type: Ci::Runner, params: { search: 'ag1' }).execute.map(&:name)

          expect(tags).to match_array %w(tag1 tag11)
        end
      end
    end

    context 'limit' do
      it 'limits the result set by the limit constant' do
        stub_const("#{described_class}::LIMIT", 1)

        create :ci_runner, tag_list: ['tag1']
        create :ci_runner, tag_list: ['tag2']

        tags = described_class.new(taggable_type: Ci::Runner, params: { search: 'tag' }).execute

        expect(tags.count).to eq 1
      end
    end
  end
end
