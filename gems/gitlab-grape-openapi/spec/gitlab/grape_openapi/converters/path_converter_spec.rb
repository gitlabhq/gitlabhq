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

    context 'with identical paths differing only by parameter name' do
      let(:routes) { TestApis::IdenticalPathsApi.routes }

      it 'groups them under a single path entry' do
        path_keys = paths.keys.select { |k| k.include?('items') }

        expect(path_keys.size).to eq(1)
      end

      it 'includes both operations under the same path' do
        path_key = paths.keys.find { |k| k.include?('items') }

        expect(paths[path_key].keys).to contain_exactly('get', 'post')
      end

      it 'uses the first route parameter name as the path key' do
        expect(paths.keys).to include('/api/v1/resources/{id}/items/{item_id}')
      end
    end

    context 'with wildcard routes' do
      # Grape registers catch-all routes with method '*' and '*path' segments.
      # This builds a duck-typed route using Grape::Router::Route's public API
      # (pattern.origin and options[:method]).
      def build_fake_route(origin:, method:)
        pattern = Struct.new(:origin).new(origin)
        Struct.new(:pattern, :options).new(pattern, { method: method, params: {} })
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
