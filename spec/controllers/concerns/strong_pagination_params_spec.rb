# frozen_string_literal: true

require 'spec_helper'

RSpec.describe StrongPaginationParams, feature_category: :tooling do
  let(:controller_class) do
    # rubocop:disable Rails/ApplicationController -- needed to isolate the concern
    Class.new(ActionController::Base) do
      include StrongPaginationParams
    end
    # rubocop:enable Rails/ApplicationController
  end

  subject(:controller) { controller_class.new }

  it 'returns an empty hash if params are not present' do
    allow(controller).to receive(:params) do
      ActionController::Parameters.new({})
    end

    expect(controller.pagination_params).to eq({})
  end

  it 'cleans up any params that are not allowed / relevant' do
    allow(controller).to receive(:params) do
      ActionController::Parameters.new(
        page: 1,
        per_page: 20,
        limit: 20,
        sort: 'asc',
        order_by: 'created_at',
        pagination: 'keyset',
        id: 1,
        something: 'else'
      )
    end

    expect(controller.pagination_params.keys).to contain_exactly(*%w[page per_page limit sort order_by pagination])
  end

  it 'returns a StrongParameters object' do
    allow(controller).to receive(:params) do
      ActionController::Parameters.new(
        page: 1
      )
    end

    expect(controller.pagination_params.permitted?).to be true
  end
end
