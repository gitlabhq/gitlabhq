require 'spec_helper'

describe PaginationHelper do
  describe '#paginate_collection' do
    let(:collection) { User.all.page(1) }

    it 'paginates a collection without using a COUNT' do
      without_count = collection.without_count

      expect(helper).to receive(:paginate_without_count)
        .with(without_count)
        .and_call_original

      helper.paginate_collection(without_count)
    end

    it 'paginates a collection using a COUNT' do
      expect(helper).to receive(:paginate_with_count).and_call_original

      helper.paginate_collection(collection)
    end
  end
end
