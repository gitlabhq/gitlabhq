# frozen_string_literal: true

RSpec.describe Gitlab::GrapeOpenapi::Converters::OperationConverter do
  let(:api_prefix) { '/api' }
  let(:api_version) { 'v1' }

  def api_prefix_camelized
    "Api#{api_version.capitalize}"
  end

  def find_route_by_method(routes, method)
    routes.find { |r| r.instance_variable_get(:@options)[:method] == method }
  end

  def find_route_by_pattern(routes, pattern)
    routes.find do |r|
      r.instance_variable_get(:@pattern).instance_variable_get(:@origin) == pattern
    end
  end

  describe '.convert' do
    context 'with simple routes' do
      let(:routes) { TestApis::UsersApi.routes }

      context 'with GET route' do
        subject(:operation) { described_class.convert(find_route_by_method(routes, 'GET')) }

        it 'generates correct operation_id' do
          expect(operation.operation_id).to eq("get#{api_prefix_camelized}Users")
        end

        it 'extracts description' do
          expect(operation.description).to eq('Get all users')
        end

        it 'extracts tags' do
          expect(operation.tags).to eq(['users'])
        end
      end

      context 'with POST route' do
        subject(:operation) { described_class.convert(find_route_by_method(routes, 'POST')) }

        it 'generates correct operation_id' do
          expect(operation.operation_id).to eq("post#{api_prefix_camelized}Users")
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
      let(:routes) { TestApis::NestedApi.routes }

      it 'generates unique operation IDs for all routes' do
        operation_ids = routes.map { |route| described_class.convert(route).operation_id }

        expect(operation_ids).to contain_exactly(
          "get#{api_prefix_camelized}Users",
          "get#{api_prefix_camelized}AdminUsers",
          "get#{api_prefix_camelized}ProjectsProjectIdUsers",
          "get#{api_prefix_camelized}ProjectsProjectIdMergeRequests",
          "get#{api_prefix_camelized}ProjectsProjectIdMergeRequestsMergeRequestIdComments",
          "post#{api_prefix_camelized}ProjectsProjectIdMergeRequestsMergeRequestIdComments",
          "post#{api_prefix_camelized}ProjectsProjectIdUsers"
        )
      end

      it 'has no duplicate operation IDs' do
        operation_ids = routes.map { |route| described_class.convert(route).operation_id }

        expect(operation_ids.uniq.size).to eq(operation_ids.size)
      end

      context 'with /api/:version/users route' do
        it 'generates simple operation_id' do
          route = find_route_by_pattern(routes, "#{api_prefix}/:version/users")
          operation = described_class.convert(route)
          expect(operation.operation_id).to eq("get#{api_prefix_camelized}Users")
        end
      end

      context 'with /api/:version/admin/users route' do
        it 'generates operation_id with admin prefix' do
          route = find_route_by_pattern(routes, "#{api_prefix}/:version/admin/users")
          operation = described_class.convert(route)
          expect(operation.operation_id).to eq("get#{api_prefix_camelized}AdminUsers")
        end

        it 'extracts correct tags' do
          route = find_route_by_pattern(routes, "#{api_prefix}/:version/admin/users")
          operation = described_class.convert(route)
          expect(operation.tags).to eq(['admin'])
        end
      end

      context 'with /api/:version/projects/:project_id/users route' do
        it 'generates operation_id with all segments' do
          route = find_route_by_pattern(routes, "#{api_prefix}/:version/projects/:project_id/users")
          operation = described_class.convert(route)
          expect(operation.operation_id).to eq("get#{api_prefix_camelized}ProjectsProjectIdUsers")
        end

        it 'extracts correct tags from first segment' do
          route = find_route_by_pattern(routes, "#{api_prefix}/:version/projects/:project_id/users")
          operation = described_class.convert(route)
          expect(operation.tags).to eq(['projects'])
        end
      end

      context 'with /api/:version/projects/:project_id/merge_requests route' do
        it 'generates operation_id with camelized segments' do
          route = find_route_by_pattern(routes, "#{api_prefix}/:version/projects/:project_id/merge_requests")
          operation = described_class.convert(route)
          expect(operation.operation_id).to eq("get#{api_prefix_camelized}ProjectsProjectIdMergeRequests")
        end

        it 'preserves underscores in tags' do
          route = find_route_by_pattern(routes, "#{api_prefix}/:version/projects/:project_id/merge_requests")
          operation = described_class.convert(route)
          expect(operation.tags).to eq(['projects'])
        end
      end
    end
  end
end
