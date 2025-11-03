# frozen_string_literal: true

RSpec.describe Gitlab::GrapeOpenapi::Converters::OperationConverter do
  let(:schema_registry) { Gitlab::GrapeOpenapi::SchemaRegistry.new }
  let(:api_classes) { [TestApis::NestedApi] }
  let(:routes) { api_classes.flat_map(&:routes) }

  describe '.convert' do
    context 'with simple routes' do
      let(:api_classes) { [TestApis::UsersApi] }

      context 'with GET route' do
        let(:route) { routes.find { |r| r.instance_variable_get(:@options)[:method] == 'GET' } }

        subject(:operation) { described_class.convert(route, schema_registry) }

        it 'generates correct operation_id' do
          expect(operation.operation_id).to eq('getApiV1Users')
        end

        it 'extracts description' do
          expect(operation.description).to eq('Get all users')
        end

        it 'extracts tags' do
          expect(operation.tags).to eq(['users'])
        end
      end

      context 'with POST route' do
        let(:route) { routes.find { |r| r.instance_variable_get(:@options)[:method] == 'POST' } }

        subject(:operation) { described_class.convert(route, schema_registry) }

        it 'generates correct operation_id' do
          expect(operation.operation_id).to eq('postApiV1Users')
        end

        it 'extracts description' do
          expect(operation.description).to eq('Create a user')
        end

        it 'extracts tags' do
          expect(operation.tags).to eq(['users'])
        end
      end
    end

    context 'with nested routes to ensure uniqueness' do
      let(:operations) do
        routes.map { |route| described_class.convert(route, schema_registry) }
      end

      it 'generates unique operation IDs for all routes' do
        operation_ids = operations.map(&:operation_id)

        expect(operation_ids).to eq(%w[
          getApiV1Users
          getApiV1AdminUsers
          getApiV1ProjectsProjectIdUsers
          postApiV1ProjectsProjectIdUsers
          getApiV1ProjectsProjectIdMergeRequests
          getApiV1ProjectsProjectIdMergeRequestsMergeRequestIdComments
          postApiV1ProjectsProjectIdMergeRequestsMergeRequestIdComments
        ])
      end

      it 'has no duplicate operation IDs' do
        operation_ids = operations.map(&:operation_id)
        expect(operation_ids.uniq.length).to eq(operation_ids.length)
      end

      context 'with /api/:version/users route' do
        let(:route) do
          routes.find do |r|
            r.instance_variable_get(:@pattern).instance_variable_get(:@origin) == '/api/:version/users'
          end
        end

        subject(:operation) { described_class.convert(route, schema_registry) }

        it 'generates simple operation_id' do
          expect(operation.operation_id).to eq('getApiV1Users')
        end
      end

      context 'with /api/:version/admin/users route' do
        let(:route) do
          routes.find do |r|
            r.instance_variable_get(:@pattern).instance_variable_get(:@origin) == '/api/:version/admin/users'
          end
        end

        subject(:operation) { described_class.convert(route, schema_registry) }

        it 'generates operation_id with admin prefix' do
          expect(operation.operation_id).to eq('getApiV1AdminUsers')
        end

        it 'extracts correct tags' do
          expect(operation.tags).to eq(['admin'])
        end
      end

      context 'with /api/:version/projects/:project_id/users route' do
        let(:route) do
          routes.find do |r|
            r.instance_variable_get(:@pattern).instance_variable_get(:@origin) ==
              '/api/:version/projects/:project_id/users' &&
              r.instance_variable_get(:@options)[:method] == 'GET'
          end
        end

        subject(:operation) { described_class.convert(route, schema_registry) }

        it 'generates operation_id with all segments' do
          expect(operation.operation_id).to eq('getApiV1ProjectsProjectIdUsers')
        end

        it 'extracts correct tags from first segment' do
          expect(operation.tags).to eq(['projects'])
        end
      end

      context 'with /api/:version/projects/:project_id/merge_requests route' do
        let(:route) do
          routes.find do |r|
            r.instance_variable_get(:@pattern).instance_variable_get(:@origin) ==
              '/api/:version/projects/:project_id/merge_requests'
          end
        end

        subject(:operation) { described_class.convert(route, schema_registry) }

        it 'generates operation_id with camelized segments' do
          expect(operation.operation_id).to eq('getApiV1ProjectsProjectIdMergeRequests')
        end

        it 'preserves underscores in tags' do
          expect(operation.tags).to eq(['projects'])
        end
      end
    end
  end
end
