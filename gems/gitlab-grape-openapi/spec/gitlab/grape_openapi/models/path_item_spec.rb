# frozen_string_literal: true

RSpec.describe Gitlab::GrapeOpenapi::Models::PathItem do
  subject(:path_item) { described_class.new }

  describe '#initialize' do
    it 'initializes with empty operations hash' do
      expect(path_item.operations).to eq({})
    end
  end

  describe '#add_operation' do
    let(:operation) { Gitlab::GrapeOpenapi::Models::Operation.new }

    before do
      operation.operation_id = 'getUsers'
      operation.description = 'Get all users'
    end

    it 'adds operation with lowercase method key' do
      path_item.add_operation('GET', operation)

      expect(path_item.operations['get']).to eq(operation)
    end

    it 'handles symbol method' do
      path_item.add_operation(:post, operation)

      expect(path_item.operations['post']).to eq(operation)
    end

    it 'handles already lowercase method' do
      path_item.add_operation('delete', operation)

      expect(path_item.operations['delete']).to eq(operation)
    end

    it 'adds multiple operations' do
      get_operation = Gitlab::GrapeOpenapi::Models::Operation.new
      get_operation.operation_id = 'getUser'

      post_operation = Gitlab::GrapeOpenapi::Models::Operation.new
      post_operation.operation_id = 'createUser'

      path_item.add_operation('GET', get_operation)
      path_item.add_operation('POST', post_operation)

      expect(path_item.operations.keys).to contain_exactly('get', 'post')
      expect(path_item.operations['get']).to eq(get_operation)
      expect(path_item.operations['post']).to eq(post_operation)
    end
  end

  describe '#to_h' do
    context 'with no operations' do
      it 'returns empty hash' do
        expect(path_item.to_h).to eq({})
      end
    end

    context 'with single operation' do
      before do
        operation = Gitlab::GrapeOpenapi::Models::Operation.new
        operation.operation_id = 'getIssues'
        operation.description = 'Get all issues'
        operation.tags = ['issues']

        path_item.add_operation('GET', operation)
      end

      it 'serializes operation' do
        result = path_item.to_h

        expect(result['get']).to eq({
          operationId: 'getIssues',
          description: 'Get all issues',
          tags: ['issues']
        })
      end
    end

    context 'with multiple operations' do
      before do
        get_operation = Gitlab::GrapeOpenapi::Models::Operation.new
        get_operation.operation_id = 'getUser'
        get_operation.description = 'Get a user'
        get_operation.tags = ['users']

        post_operation = Gitlab::GrapeOpenapi::Models::Operation.new
        post_operation.operation_id = 'createUser'
        post_operation.description = 'Create a user'
        post_operation.tags = ['users']

        delete_operation = Gitlab::GrapeOpenapi::Models::Operation.new
        delete_operation.operation_id = 'deleteUser'
        delete_operation.description = 'Delete a user'
        delete_operation.tags = ['users']

        path_item.add_operation('GET', get_operation)
        path_item.add_operation('POST', post_operation)
        path_item.add_operation('DELETE', delete_operation)
      end

      it 'serializes all operations' do
        result = path_item.to_h

        expect(result.keys).to contain_exactly('get', 'post', 'delete')
        expect(result['get'][:operationId]).to eq('getUser')
        expect(result['post'][:operationId]).to eq('createUser')
        expect(result['delete'][:operationId]).to eq('deleteUser')
      end
    end
  end
end
