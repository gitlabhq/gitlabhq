# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GrapeOpenapi::Converters::PathConverter do
  let(:api_prefix) { '/api' }
  let(:api_version) { 'v1' }
  let(:base_path) { "#{api_prefix}/#{api_version}" }

  describe '.convert' do
    let(:users_api) { TestApis::UsersApi }
    let(:routes) { users_api.routes }

    subject(:paths) { described_class.convert(routes) }

    it 'groups routes by normalized path' do
      expect(paths.keys).to eq(["#{base_path}/users", '/api/v1/users/{id}'])
    end

    it 'includes both operations' do
      expect(paths["#{base_path}/users"].keys).to contain_exactly('get', 'options', 'post')
    end

    it 'has correct GET operation details' do
      get_operation = paths["#{base_path}/users"]['get']

      expect(get_operation[:operationId]).to eq('getApiV1Users')
      expect(get_operation[:description]).to eq('Get all users')
      expect(get_operation[:tags]).to eq(['users'])
    end

    it 'has correct POST operation details' do
      post_operation = paths["#{base_path}/users"]['post']

      expect(post_operation[:operationId]).to eq('postApiV1Users')
      expect(post_operation[:description]).to eq('Create a user')
      expect(post_operation[:tags]).to eq(['users'])
    end

    context 'with empty routes' do
      let(:routes) { [] }

      it 'returns empty hash' do
        expect(paths).to eq({})
      end
    end
  end
end
