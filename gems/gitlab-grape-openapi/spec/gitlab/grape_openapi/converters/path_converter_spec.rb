# frozen_string_literal: true

RSpec.describe Gitlab::GrapeOpenapi::Converters::PathConverter do
  let(:schema_registry) { Gitlab::GrapeOpenapi::SchemaRegistry.new }
  let(:request_body_registry) { Gitlab::GrapeOpenapi::RequestBodyRegistry.new }
  let(:routes) { TestApis::UsersApi.routes }

  describe '.convert' do
    subject(:paths) { described_class.convert(routes, schema_registry, request_body_registry) }

    it 'groups routes by normalized path' do
      expect(paths.keys).to include('/api/v1/users')
    end

    it 'includes both operations' do
      expect(paths['/api/v1/users'].keys).to include('get', 'post')
    end

    it 'has correct GET operation details' do
      get_operation = paths['/api/v1/users']['get']

      expect(get_operation[:operationId]).to eq('getApiV1Users')
      expect(get_operation[:description]).to eq('Returns a list of all users')
    end

    it 'has correct POST operation details' do
      post_operation = paths['/api/v1/users']['post']

      expect(post_operation[:operationId]).to eq('postApiV1Users')
      expect(post_operation[:description]).to eq('Creates a new user with the provided information')
    end

    context 'with empty routes' do
      let(:routes) { [] }

      it 'returns empty hash' do
        expect(paths).to eq({})
      end
    end

    context 'when all operations for a path are hidden' do
      let(:routes) { TestApis::HiddenApi.routes }

      it 'excludes the path entirely' do
        expect(paths).to be_empty
      end
    end

    context 'with wildcard routes' do
      # Grape registers catch-all routes with method '*' and '*path' segments.
      # This method builds a fake route that mimics Grape::Router::Route's
      # internal structure (instance variables @pattern and @options) because
      # PathConverter reads them via instance_variable_get.
      def build_fake_route(origin:, method:)
        pattern = Object.new
        pattern.instance_variable_set(:@origin, origin)

        route = Object.new
        route.instance_variable_set(:@pattern, pattern)
        route.instance_variable_set(:@options, { method: method, params: {} })
        route
      end

      let(:wildcard_route) { build_fake_route(origin: '/api/:version/*path(.:format)', method: '*') }

      let(:routes) { TestApis::UsersApi.routes + [wildcard_route] }

      it 'excludes wildcard routes from output' do
        expect(paths.keys).not_to include(a_string_matching(/\*/))
      end

      it 'still includes normal routes' do
        expect(paths.keys).to include('/api/v1/users')
      end
    end
  end
end
