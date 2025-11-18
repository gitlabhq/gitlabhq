# frozen_string_literal: true

RSpec.describe Gitlab::GrapeOpenapi::Models::Operation do
  subject(:operation) { described_class.new }

  describe '#initialize' do
    it 'initializes with empty tags array' do
      expect(operation.tags).to eq([])
    end

    it 'initializes with an empty parameters array' do
      expect(operation.parameters).to eq([])
    end

    it 'initializes other fields as nil' do
      expect(operation.operation_id).to be_nil
      expect(operation.description).to be_nil
    end
  end

  describe '#to_h' do
    context 'with minimal fields' do
      before do
        operation.operation_id = 'getUsers'
        operation.description = 'Get all users'
      end

      it 'includes set fields' do
        result = operation.to_h

        expect(result[:operationId]).to eq('getUsers')
        expect(result[:description]).to eq('Get all users')
      end

      it 'omits empty tags array' do
        result = operation.to_h

        expect(result).not_to have_key(:tags)
      end
    end

    context 'with all fields populated' do
      before do
        operation.operation_id = 'createUser'
        operation.description = 'Creates a new user in the system'
        operation.tags = %w[users admin]
      end

      it 'includes all fields' do
        result = operation.to_h

        expect(result[:operationId]).to eq('createUser')
        expect(result[:description]).to eq('Creates a new user in the system')
        expect(result[:tags]).to eq(%w[users admin])
      end
    end

    context 'with tags' do
      before do
        operation.operation_id = 'getIssues'
        operation.tags = ['issues']
      end

      it 'includes tags when present' do
        result = operation.to_h

        expect(result[:tags]).to eq(['issues'])
      end
    end

    context 'with custom responses' do
      before do
        operation.operation_id = 'deleteUser'
        operation.responses = {
          '204' => { description: 'User deleted' },
          '404' => { description: 'User not found' }
        }
      end

      it 'uses custom responses' do
        result = operation.to_h

        expect(result[:responses]).to eq({
          '204' => { description: 'User deleted' },
          '404' => { description: 'User not found' }
        })
      end
    end

    context 'without description' do
      before do
        operation.operation_id = 'getProjects'
      end

      it 'omits nil description' do
        result = operation.to_h

        expect(result).not_to have_key(:description)
      end
    end
  end
end
