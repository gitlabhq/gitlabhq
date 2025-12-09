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
          expect(operation.description).to eq('Returns a list of all users')
        end

        it 'extracts tags' do
          expect(operation.tags).to eq(['Users Api'])
        end

        it 'extracts parameters' do
          expect(operation.parameters.size).to eq(3)
        end

        it 'extracts summary from description' do
          expect(operation.summary).to eq('Get all users')
        end

        it 'has responses' do
          expect(operation.responses).to be_a(Hash)
          expect(operation.responses).not_to be_empty
        end

        it 'has request_body as empty hash for GET requests' do
          expect(operation.request_body).to eq({})
        end

        it 'verifies parameter content' do
          param_names = operation.parameters.map(&:name)
          expect(param_names).to include('active', 'username', 'tag')
        end
      end

      context 'with POST route' do
        let(:route) { routes.find { |r| r.instance_variable_get(:@options)[:method] == 'POST' } }

        subject(:operation) { described_class.convert(route, schema_registry) }

        it 'generates correct operation_id' do
          expect(operation.operation_id).to eq('postApiV1Users')
        end

        it 'extracts description' do
          expect(operation.description).to eq('Creates a new user with the provided information')
        end

        it 'extracts tags' do
          expect(operation.tags).to eq(['Users Api'])
        end

        it 'extracts summary from description' do
          expect(operation.summary).to eq('Create a user')
        end

        it 'has request_body for POST requests' do
          expect(operation.request_body).not_to be_empty
        end

        it 'has responses' do
          expect(operation.responses).to be_a(Hash)
          expect(operation.responses).not_to be_empty
        end
      end

      context 'with PUT route' do
        let(:route) { routes.find { |r| r.instance_variable_get(:@options)[:method] == 'PUT' } }

        subject(:operation) { described_class.convert(route, schema_registry) }

        it 'generates correct operation_id' do
          expect(operation.operation_id).to eq('putApiV1UsersId')
        end

        it 'extracts description' do
          expect(operation.description).to eq('Replaces all user information with the provided data')
        end

        it 'extracts summary' do
          expect(operation.summary).to eq('Update a user (full replacement)')
        end
      end

      context 'with PATCH route' do
        let(:route) { routes.find { |r| r.instance_variable_get(:@options)[:method] == 'PATCH' } }

        subject(:operation) { described_class.convert(route, schema_registry) }

        it 'generates correct operation_id' do
          expect(operation.operation_id).to eq('patchApiV1UsersId')
        end

        it 'extracts description' do
          expect(operation.description).to eq('Updates only the specified user fields')
        end

        it 'extracts summary' do
          expect(operation.summary).to eq('Update a user (partial)')
        end
      end

      context 'with DELETE route' do
        let(:route) { routes.find { |r| r.instance_variable_get(:@options)[:method] == 'DELETE' } }

        subject(:operation) { described_class.convert(route, schema_registry) }

        it 'generates correct operation_id' do
          expect(operation.operation_id).to eq('deleteApiV1UsersId')
        end

        it 'extracts description' do
          expect(operation.description).to eq('Permanently removes a user from the system')
        end

        it 'extracts summary' do
          expect(operation.summary).to eq('Delete a user')
        end
      end

      context 'with HEAD route' do
        let(:route) { routes.find { |r| r.instance_variable_get(:@options)[:method] == 'HEAD' } }

        subject(:operation) { described_class.convert(route, schema_registry) }

        it 'generates correct operation_id' do
          expect(operation.operation_id).to eq('headApiV1UsersId')
        end

        it 'extracts summary' do
          expect(operation.summary).to eq('Get user headers')
        end
      end

      context 'with OPTIONS route' do
        let(:route) { routes.find { |r| r.instance_variable_get(:@options)[:method] == 'OPTIONS' } }

        subject(:operation) { described_class.convert(route, schema_registry) }

        it 'generates correct operation_id' do
          expect(operation.operation_id).to eq('optionsApiV1Users')
        end

        it 'extracts description' do
          expect(operation.description).to eq('Gets available options')
        end

        it 'extracts summary' do
          expect(operation.summary).to eq('Get available options')
        end

        it 'extracts tags with different format' do
          expect(operation.tags).to eq(['Users'])
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

        it 'extracts summary from simple desc string' do
          expect(operation.summary).to eq('2 levels of nesting with different resource')
        end
      end

      context 'with route having no detail' do
        let(:route) do
          routes.find do |r|
            r.instance_variable_get(:@pattern).instance_variable_get(:@origin) == '/api/:version/users'
          end
        end

        subject(:operation) { described_class.convert(route, schema_registry) }

        it 'has nil description when no detail provided' do
          expect(operation.description).to be_nil
        end

        it 'still extracts summary from desc string' do
          expect(operation.summary).to eq('No nesting')
        end
      end
    end

    context 'with parameters' do
      let(:api_classes) { [TestApis::UsersApi] }
      let(:route) { routes.find { |r| r.instance_variable_get(:@options)[:method] == 'GET' } }

      subject(:operation) { described_class.convert(route, schema_registry) }

      it 'extracts parameter details correctly' do
        params = operation.parameters
        expect(params.size).to eq(3)

        active_param = params.find { |p| p.name == 'active' }
        expect(active_param).not_to be_nil
        expect(active_param.description).to eq('Filter by active users')

        username_param = params.find { |p| p.name == 'username' }
        expect(username_param).not_to be_nil
        expect(username_param.description).to eq('Find by username')

        tag_param = params.find { |p| p.name == 'tag' }
        expect(tag_param).not_to be_nil
        expect(tag_param.description).to eq('Hello tag')
      end
    end

    context 'with special characters in paths' do
      let(:api_classes) { [TestApis::NestedApi] }
      let(:route) do
        routes.find do |r|
          r.instance_variable_get(:@pattern).instance_variable_get(:@origin) ==
            '/api/:version/projects/:project_id/merge_requests'
        end
      end

      subject(:operation) { described_class.convert(route, schema_registry) }

      it 'camelizes paths with underscores correctly' do
        expect(operation.operation_id).to include('MergeRequests')
      end
    end

    context 'with request body' do
      let(:api_classes) { [TestApis::UsersApi] }
      let(:post_route) { routes.find { |r| r.instance_variable_get(:@options)[:method] == 'POST' } }
      let(:get_route) { routes.find { |r| r.instance_variable_get(:@options)[:method] == 'GET' } }

      it 'includes request_body for POST request' do
        operation = described_class.convert(post_route, schema_registry)
        expect(operation.request_body).not_to be_empty
        expect(operation.request_body).to be_a(Hash)
      end

      it 'has empty request_body for GET request' do
        operation = described_class.convert(get_route, schema_registry)
        expect(operation.request_body).to eq({})
      end
    end

    context 'with responses' do
      let(:api_classes) { [TestApis::UsersApi] }
      let(:route) { routes.first }

      subject(:operation) { described_class.convert(route, schema_registry) }

      it 'converts responses using ResponseConverter' do
        expect(operation.responses).to be_a(Hash)
        expect(operation.responses).not_to be_empty
      end
    end

    context 'with edge cases' do
      let(:api_classes) { [TestApis::NestedApi] }

      context 'with route having no tags' do
        let(:route) do
          routes.find do |r|
            r.instance_variable_get(:@pattern).instance_variable_get(:@origin) == '/api/:version/users'
          end
        end

        subject(:operation) { described_class.convert(route, schema_registry) }

        it 'returns nil for tags when not specified' do
          expect(operation.tags).to be_empty
        end
      end

      context 'with route having no params' do
        let(:route) do
          routes.find do |r|
            r.instance_variable_get(:@pattern).instance_variable_get(:@origin) == '/api/:version/users'
          end
        end

        subject(:operation) { described_class.convert(route, schema_registry) }

        it 'returns empty array for parameters' do
          expect(operation.parameters).to eq([])
        end
      end

      context 'with camelize functionality' do
        it 'handles underscores in operation_id' do
          route = routes.find do |r|
            r.instance_variable_get(:@pattern).instance_variable_get(:@origin) ==
              '/api/:version/projects/:project_id/merge_requests/:merge_request_id/comments'
          end
          operation = described_class.convert(route, schema_registry)

          expect(operation.operation_id).to eq('getApiV1ProjectsProjectIdMergeRequestsMergeRequestIdComments')
          expect(operation.operation_id).to include('MergeRequests')
          expect(operation.operation_id).to include('MergeRequestId')
        end
      end

      context 'with multiple path parameters' do
        let(:route) do
          routes.find do |r|
            r.instance_variable_get(:@pattern).instance_variable_get(:@origin) ==
              '/api/:version/projects/:project_id/merge_requests/:merge_request_id/comments' &&
              r.instance_variable_get(:@options)[:method] == 'POST'
          end
        end

        subject(:operation) { described_class.convert(route, schema_registry) }

        it 'includes all path parameters in operation_id' do
          expect(operation.operation_id).to include('ProjectId')
          expect(operation.operation_id).to include('MergeRequestId')
        end
      end
    end
  end

  context 'with deprecated endpoints' do
    let(:api_classes) { [TestApis::DeprecatedApi] }
    let(:schema_registry) { Gitlab::GrapeOpenapi::SchemaRegistry.new }

    context 'with deprecated true directive' do
      let(:route) { routes.find { |r| r.path.include?('directive') } }

      subject(:operation) { described_class.convert(route, schema_registry) }

      it 'sets deprecated to true' do
        expect(operation.deprecated).to be true
      end

      it 'includes deprecated in output' do
        expect(operation.to_h[:deprecated]).to be true
      end
    end

    context 'with non-deprecated endpoint' do
      let(:route) { routes.find { |r| r.path.include?('normal') } }

      subject(:operation) { described_class.convert(route, schema_registry) }

      it 'does not set deprecated' do
        expect(operation.deprecated).to be_falsey
      end
    end
  end
end
