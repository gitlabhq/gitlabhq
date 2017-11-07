require 'spec_helper'

describe IssuableCollections do
  let(:user) { create(:user) }

  let(:controller) do
    klass = Class.new do
      def self.helper_method(name); end

      include IssuableCollections
    end

    controller = klass.new

    allow(controller).to receive(:params).and_return(state: 'opened')

    controller
  end

  describe '#page_count_for_relation' do
    it 'returns the number of pages' do
      relation = double(:relation, limit_value: 20)
      pages = controller.send(:page_count_for_relation, relation, 28)

      expect(pages).to eq(2)
    end
  end
end
