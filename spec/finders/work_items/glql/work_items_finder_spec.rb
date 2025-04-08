# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Glql::WorkItemsFinder, feature_category: :markdown do
  let_it_be(:resource_parent) { create(:group) }
  let(:current_user)     { create(:user) }
  let(:context)          { instance_double(GraphQL::Query::Context) }
  let(:params)           { {} }
  let(:dummy_request) do
    instance_double(ActionDispatch::Request, params: {}, referer: 'http://localhost')
  end

  subject(:finder) { described_class.new(current_user, context, resource_parent, params) }

  describe '#use_elasticsearch_finder?' do
    before do
      allow(context).to receive(:[]).with(:request).and_return(dummy_request)
    end

    it 'returns false by default' do
      expect(finder.use_elasticsearch_finder?).to be_falsey
    end
  end
end
