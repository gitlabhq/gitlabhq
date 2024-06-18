# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'DeclarativePolicy authorization in GraphQL ' do
  include GraphqlHelpers
  include Graphql::ResolverFactories

  let_it_be(:user) { create(:user) }

  let(:permission_single) { :foo }
  let(:permission_collection) { [:foo, :bar] }
  let(:test_object) { double(name: 'My name', address: 'Worldwide') }
  let(:authorizing_object) { test_object }
  # to override when combining permissions
  let(:permission_object_one) { authorizing_object }
  let(:permission_object_two) { authorizing_object }

  let(:query_string) { '{ item { name } }' }
  let(:result) { execute_query(query_type) }

  subject { result.dig('data', 'item') }

  shared_examples 'authorization with a single permission' do
    it 'returns the protected field when user has permission' do
      permit(permission_single)

      expect(subject).to eq('name' => test_object.name)
    end

    it 'returns nil when user is not authorized' do
      expect(subject).to be_nil
    end
  end

  shared_examples 'authorization with a collection of permissions' do
    it 'returns the protected field when user has all permissions' do
      permit_on(permission_object_one, permission_collection.first)
      permit_on(permission_object_two, permission_collection.second)

      expect(subject).to eq('name' => test_object.name)
    end

    it 'returns nil when user only has one of the permissions' do
      permit_on(permission_object_one, permission_collection.first)

      expect(subject).to be_nil
    end

    it 'returns nil when user only has the other of the permissions' do
      permit_on(permission_object_two, permission_collection.second)

      expect(subject).to be_nil
    end

    it 'returns nil when user has neither of the required permissions' do
      expect(subject).to be_nil
    end
  end

  before do
    # By default, disallow all permissions.
    allow(Ability).to receive(:allowed?).and_return(false)
  end

  describe 'Field authorizations' do
    let(:type) { type_factory }
    let(:authorizing_object) { nil }

    describe 'with a single permission' do
      let(:query_type) do
        query_factory do |query|
          query.field :item, type, null: true, resolver: new_resolver(test_object), authorize: permission_single
        end
      end

      include_examples 'authorization with a single permission'
    end

    describe 'with a collection of permissions' do
      let(:query_type) do
        permissions = permission_collection
        query_factory do |qt|
          qt.field :item, type,
            null: true,
            resolver: new_resolver(test_object),
            authorize: permissions
        end
      end

      include_examples 'authorization with a collection of permissions'
    end
  end

  describe 'Field authorizations when field is a built in type' do
    let(:query_type) do
      query_factory do |query|
        query.field :item, type, null: true, resolver: new_resolver(test_object)
      end
    end

    describe 'with a single permission' do
      let(:query_string) { '{ item { name address } }' }
      let(:type) do
        type_factory do |type|
          type.field :address, GraphQL::Types::String, null: true, authorize: permission_single
        end
      end

      it 'returns the protected field when user has permission' do
        permit(permission_single)

        expect(subject).to include('address' => test_object.address)
      end

      it 'returns nil when user is not authorized' do
        expect(subject).to include('address' => nil)
      end
    end

    describe 'with a collection of permissions' do
      let(:query_string) { '{ item { name address } }' }
      let(:type) do
        permissions = permission_collection
        type_factory do |type|
          type.field :address, GraphQL::Types::String, null: true, authorize: permissions
        end
      end

      it 'returns the protected field when user has all permissions' do
        permit(*permission_collection)

        expect(subject).to include('address' => test_object.address)
      end

      it 'returns nil when user only has one of the permissions' do
        permit(permission_collection.first)

        expect(subject).to include('address' => nil)
      end

      it 'returns nil when user only has none of the permissions' do
        expect(subject).to include('address' => nil)
      end
    end
  end

  describe 'Type authorizations' do
    let(:query_type) do
      query_factory do |query|
        query.field :item, type, null: true, resolver: new_resolver(test_object)
      end
    end

    describe 'with a single permission' do
      let(:type) do
        type_factory do |type|
          type.authorize permission_single
        end
      end

      include_examples 'authorization with a single permission'
    end

    describe 'with a collection of permissions' do
      let(:type) do
        type_factory do |type|
          type.authorize permission_collection
        end
      end

      include_examples 'authorization with a collection of permissions'
    end
  end

  describe 'type and field authorizations together' do
    let(:authorizing_object) { anything }
    let(:permission_1) { permission_collection.first }
    let(:permission_2) { permission_collection.second }

    let(:type) do
      type_factory do |type|
        type.authorize permission_1
      end
    end

    let(:query_type) do
      query_factory do |query|
        query.field :item, type, null: true, resolver: new_resolver(test_object), authorize: permission_2
      end
    end

    include_examples 'authorization with a collection of permissions'
  end

  describe 'resolver and field authorizations together' do
    let(:permission_1) { permission_collection.first }
    let(:permission_2) { permission_collection.last }
    let(:type) { type_factory }

    let(:query_type) do
      query_factory do |query|
        query.field :item, type,
          null: true,
          resolver: resolver,
          authorize: permission_2
      end
    end

    context 'when the resolver authorizes the object' do
      let(:permission_object_one) { be_nil }
      let(:permission_object_two) { be_nil }
      let(:resolver) do
        resolver = simple_resolver(test_object)
        resolver.include(::Gitlab::Graphql::Authorize::AuthorizeResource)
        resolver.authorize permission_1
        resolver.authorizes_object!
        resolver
      end

      include_examples 'authorization with a collection of permissions'
    end

    context 'when the resolver is a subclass of one that authorizes the object' do
      let(:permission_object_one) { be_nil }
      let(:permission_object_two) { be_nil }
      let(:parent) do
        parent = Class.new(Resolvers::BaseResolver)
        parent.include(::Gitlab::Graphql::Authorize::AuthorizeResource)
        parent.authorizes_object!
        parent.authorize permission_1
        parent
      end

      let(:resolver) do
        simple_resolver(test_object, base_class: parent)
      end

      include_examples 'authorization with a collection of permissions'
    end

    context 'when the resolver is a subclass of one that authorizes the object, extra permission' do
      let(:permission_object_one) { be_nil }
      let(:permission_object_two) { be_nil }
      let(:parent) do
        parent = Class.new(Resolvers::BaseResolver)
        parent.include(::Gitlab::Graphql::Authorize::AuthorizeResource)
        parent.authorizes_object!
        parent.authorize permission_1
        parent
      end

      let(:resolver) do
        resolver = simple_resolver(test_object, base_class: parent)
        resolver.include(::Gitlab::Graphql::Authorize::AuthorizeResource)
        resolver.authorize permission_2
        resolver
      end

      context 'when the field does not define any permissions' do
        let(:query_type) do
          query_factory do |query|
            query.field :item, type,
              null: true,
              resolver: resolver
          end
        end

        include_examples 'authorization with a collection of permissions'
      end
    end

    context 'when the resolver does not authorize the object, but instead calls authorized_find!' do
      let(:permission_object_one) { test_object }
      let(:permission_object_two) { be_nil }
      let(:resolver) do
        resolver = new_resolver(test_object, method: :find_object)
        resolver.authorize permission_1
        resolver
      end

      include_examples 'authorization with a collection of permissions'
    end

    context 'when the resolver calls authorized_find!, but does not list any permissions' do
      let(:permission_object_two) { be_nil }
      let(:resolver) do
        resolver = new_resolver(test_object, method: :find_object)
        resolver
      end

      it 'raises a configuration error' do
        permit_on(permission_object_two, permission_collection.second)

        expect { execute_query(query_type) }
          .to raise_error(::Gitlab::Graphql::Authorize::AuthorizeResource::ConfigurationError)
      end
    end
  end

  describe 'when type authorizations when applied to a relay connection' do
    let(:query_string) { '{ item { edges { node { name } } } }' }
    let(:second_test_object) { double(name: 'Second thing') }

    let(:type) do
      type_factory do |type|
        type.authorize permission_single
      end
    end

    let(:query_type) do
      query_factory do |query|
        query.field :item, type.connection_type, null: true, resolver: new_resolver([test_object, second_test_object])
      end
    end

    subject { result.dig('data', 'item', 'edges') }

    it 'returns only the elements visible to the user' do
      permit(permission_single)

      expect(subject.size).to eq 1
      expect(subject.first['node']).to eq('name' => test_object.name)
    end

    it 'returns nil when user is not authorized' do
      expect(subject).to be_empty
    end

    describe 'limiting connections with multiple objects' do
      let(:query_type) do
        query_factory do |query|
          query.field :item, type.connection_type, null: true, resolver: new_resolver([test_object, second_test_object])
        end
      end

      let(:query_string) { '{ item(first: 1) { edges { node { name } } } }' }

      it 'only checks permissions for the first object' do
        expect(Ability)
          .to receive(:allowed?)
          .with(user, permission_single, test_object)
          .and_return(true)
        expect(Ability)
          .not_to receive(:allowed?).with(user, permission_single, second_test_object)

        expect(subject.size).to eq(1)
      end
    end
  end

  describe 'type authorizations when applied to a basic connection' do
    let(:type) do
      type_factory do |type|
        type.authorize permission_single
      end
    end

    let(:query_type) do
      query_factory do |query|
        query.field :item, [type], null: true, resolver: new_resolver([test_object])
      end
    end

    subject { result.dig('data', 'item', 0) }

    include_examples 'authorization with a single permission'
  end

  describe 'Authorizations on active record relations' do
    let!(:visible_project) { create(:project, :private) }
    let!(:other_project) { create(:project, :private) }
    let!(:visible_issues) { create_list(:issue, 2, project: visible_project) }
    let!(:other_issues) { create_list(:issue, 2, project: other_project) }
    let!(:user) { visible_project.first_owner }

    let(:issue_type) do
      type_factory do |type|
        type.graphql_name 'FakeIssueType'
        type.authorize :read_issue
        type.field :id, GraphQL::Types::ID, null: false
      end
    end

    let(:project_type) do |type|
      issues = Issue.where(project: [visible_project, other_project]).order(id: :asc)
      type_factory do |type|
        type.graphql_name 'FakeProjectType'
        type.field :test_issues, field_type,
          null: false,
          resolver: new_resolver(issues)
      end
    end

    let(:query_type) do
      query_factory do |query|
        query.field :test_project, project_type, null: false, resolver: new_resolver(visible_project)
      end
    end

    before do
      allow(Ability).to receive(:allowed?).and_call_original
    end

    context 'for connection field type' do
      let(:field_type) { issue_type.connection_type }

      let(:query_string) do
        <<~QRY
          { testProject { testIssues(first: 3) { edges { node { id } } } } }
        QRY
      end

      it 'renders the issues the user has access to' do
        issue_edges = result.dig('data', 'testProject', 'testIssues', 'edges')
        issue_ids = issue_edges.map { |issue_edge| issue_edge['node']&.fetch('id') }

        expect(issue_edges.size).to eq(visible_issues.size)
        expect(issue_ids).to eq(visible_issues.map { |i| i.to_global_id.to_s })
      end

      it 'does not check access on fields that will not be rendered' do
        expect(Ability).not_to receive(:allowed?).with(user, :read_issue, other_issues.last)

        result
      end
    end

    context 'for list field type' do
      let(:field_type) { [issue_type] }

      let(:query_string) do
        <<~QRY
          { testProject { testIssues { id } } }
        QRY
      end

      it 'renders the issues the user has access to' do
        issue_ids = result.dig('data', 'testProject', 'testIssues').pluck('id')

        expect(issue_ids).to eq(visible_issues.map { |i| i.to_global_id.to_s })
      end
    end
  end

  describe 'Authorization on GraphQL::Execution::SKIP' do
    let(:type) do
      type_factory do |type|
        type.authorize permission_single
      end
    end

    let(:query_type) do
      query_factory do |query|
        query.field :item, [type], null: true, resolver: new_resolver(GraphQL::Execution::SKIP)
      end
    end

    it 'skips redaction' do
      expect(Ability).not_to receive(:allowed?)

      result
    end
  end

  private

  def permit(*permissions)
    permit_on(authorizing_object, *permissions)
  end

  def permit_on(object, *permissions)
    permissions.each do |permission|
      allow(Ability).to receive(:allowed?).with(user, permission, object).and_return(true)
    end
  end
end
