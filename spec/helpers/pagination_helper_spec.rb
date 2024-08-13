# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PaginationHelper do
  describe '#paginate_collection' do
    let(:collection) { User.all.page(1) }

    it 'paginates a collection without using a COUNT' do
      without_count = collection.without_count

      expect(helper).to receive(:paginate_without_count)
        .with(without_count, event_tracking: 'foo_bar')
        .and_call_original

      helper.paginate_collection(without_count, event_tracking: 'foo_bar')
    end

    it 'paginates a collection using a COUNT' do
      expect(helper).to receive(:paginate_with_count)
        .with(collection, remote: nil, total_pages: nil)
        .and_call_original

      helper.paginate_collection(collection, event_tracking: 'foo_bar')
    end
  end

  describe '#paginate_event_tracking_data_attributes' do
    context 'when event_tracking argument is nil' do
      it 'returns an empty object' do
        expect(helper.paginate_event_tracking_data_attributes).to eq({})
      end
    end

    context 'when event tracking argument is set' do
      it 'returns event tracking data attributes' do
        expect(
          helper.paginate_event_tracking_data_attributes(
            event_tracking: 'foo_bar',
            event_label: 'baz'
          )
        ).to eq({
          event_tracking: 'foo_bar',
          event_label: 'baz'
        })
      end
    end
  end
end
