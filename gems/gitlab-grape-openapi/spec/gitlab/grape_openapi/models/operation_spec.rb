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

    context 'with deprecation' do
      context 'when deprecated is true' do
        it 'includes deprecated field in output' do
          operation.deprecated = true

          expect(operation.to_h[:deprecated]).to be true
        end
      end

      context 'when deprecated is false' do
        it 'does not include deprecated field in output' do
          operation.deprecated = false

          expect(operation.to_h[:deprecated]).to be_nil
        end
      end
    end

    context 'with annotations' do
      context 'when annotations is nil' do
        it 'generates hash without errors' do
          operation.operation_id = 'getUsers'
          operation.annotations = nil

          result = operation.to_h

          expect(result[:operationId]).to eq('getUsers')
        end
      end

      context 'when annotations has single entry' do
        it 'includes annotation in output' do
          operation.operation_id = 'getUsers'
          operation.annotations = { 'x-custom': 'custom-value' }

          result = operation.to_h

          expect(result[:'x-custom']).to eq('custom-value')
        end
      end

      context 'when annotations has multiple entries' do
        it 'includes all annotations in output' do
          operation.operation_id = 'getUsers'
          operation.annotations = {
            'x-custom-field': 'value1',
            'x-internal': true,
            'x-rate-limit': 100
          }

          result = operation.to_h

          expect(result[:'x-custom-field']).to eq('value1')
          expect(result[:'x-internal']).to be true
          expect(result[:'x-rate-limit']).to eq(100)
        end
      end
    end
  end
end
