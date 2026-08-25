# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PaginatedCollection, feature_category: :team_planning do
  let(:controller_class) do
    # rubocop:disable Rails/ApplicationController -- the concern only needs params and request
    Class.new(ActionController::Base) do
      include PaginatedCollection
    end
    # rubocop:enable Rails/ApplicationController
  end

  let(:request_params) { {} }

  subject(:controller) { controller_class.new }

  before do
    allow(controller).to receive_messages(
      params: ActionController::Parameters.new(request_params),
      request: instance_double(ActionDispatch::Request, format: Mime[:html])
    )
  end

  describe '#paginate_for_collection' do
    subject(:result) { controller.send(:paginate_for_collection, User.all, row_count: 250) }

    context 'when sorting by relative position' do
      let(:request_params) { { sort: 'relative_position' } }

      it 'allows 100 items on the page' do
        expect(result[:collection].limit_value).to eq(100)
        expect(result[:total_pages]).to eq(3)
      end
    end

    context 'when sorting by anything else' do
      let(:request_params) { { sort: 'created_date' } }

      it 'keeps the default page size' do
        expect(result[:collection].limit_value).to eq(User.default_per_page)
      end
    end

    context 'when the request is an atom feed' do
      let(:request_params) { { page: '4' } }

      before do
        allow(controller.request).to receive(:format).and_return(Mime[:atom])
      end

      it 'skips counting and reports one page beyond the current one' do
        expect(result[:total_pages]).to eq(5)
      end
    end
  end
end
