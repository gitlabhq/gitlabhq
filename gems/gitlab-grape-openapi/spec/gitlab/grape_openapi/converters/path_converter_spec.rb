# frozen_string_literal: true

RSpec.describe Gitlab::GrapeOpenapi::Converters::PathConverter do
  let(:schema_registry) { Gitlab::GrapeOpenapi::SchemaRegistry.new }
  let(:routes) { TestApis::UsersApi.routes }

  describe '.convert' do
    subject(:paths) { described_class.convert(routes, schema_registry) }

    it 'groups routes by normalized path' do
      expect(paths.keys).to include('/api/v1/users')
    end

    it 'includes both operations' do
      expect(paths['/api/v1/users'].keys).to include('get', 'post')
    end

    it 'has correct GET operation details' do
      get_operation = paths['/api/v1/users']['get']

      expect(get_operation[:operationId]).to eq('getApiV1Users')
      expect(get_operation[:description]).to eq('Get all users')
    end

    it 'has correct POST operation details' do
      post_operation = paths['/api/v1/users']['post']

      expect(post_operation[:operationId]).to eq('postApiV1Users')
      expect(post_operation[:description]).to eq('Create a user')
    end

    context 'with empty routes' do
      let(:routes) { [] }

      it 'returns empty hash' do
        expect(paths).to eq({})
      end
    end
  end
end
