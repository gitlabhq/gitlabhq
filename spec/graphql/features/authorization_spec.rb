# frozen_string_literal: true

require 'spec_helper'

describe 'Gitlab::Graphql::Authorization' do
  set(:user) { create(:user) }

  let(:permission_single) { :foo }
  let(:permission_collection) { [:foo, :bar] }
  let(:test_object) { double(name: 'My name') }
  let(:query_string) { '{ item() { name } }' }
  let(:result) { execute_query(query_type)['data'] }

  subject { result['item'] }

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
      permit(*permission_collection)

      expect(subject).to eq('name' => test_object.name)
    end

    it 'returns nil when user only has one of the permissions' do
      permit(permission_collection.first)

      expect(subject).to be_nil
    end

    it 'returns nil when user only has none of the permissions' do
      expect(subject).to be_nil
    end
  end

  before do
    # By default, disallow all permissions.
    allow(Ability).to receive(:allowed?).and_return(false)
  end

  describe 'Field authorizations' do
    let(:type) { type_factory }

    describe 'with a single permission' do
      let(:query_type) do
        query_factory do |query|
          query.field :item, type, null: true, resolve: ->(obj, args, ctx) { test_object }, authorize: permission_single
        end
      end

      include_examples 'authorization with a single permission'
    end

    describe 'with a collection of permissions' do
      let(:query_type) do
        permissions = permission_collection
        query_factory do |qt|
          qt.field :item, type, null: true, resolve: ->(obj, args, ctx) { test_object } do
            authorize permissions
          end
        end
      end

      include_examples 'authorization with a collection of permissions'
    end
  end

  describe 'Field authorizations when field is a built in type' do
    let(:query_type) do
      query_factory do |query|
        query.field :item, type, null: true, resolve: ->(obj, args, ctx) { test_object }
      end
    end

    describe 'with a single permission' do
      let(:type) do
        type_factory do |type|
          type.field :name, GraphQL::STRING_TYPE, null: true, authorize: permission_single
        end
      end

      it 'returns the protected field when user has permission' do
        permit(permission_single)

        expect(subject).to eq('name' => test_object.name)
      end

      it 'returns nil when user is not authorized' do
        expect(subject).to eq('name' => nil)
      end
    end

    describe 'with a collection of permissions' do
      let(:type) do
        permissions = permission_collection
        type_factory do |type|
          type.field :name, GraphQL::STRING_TYPE, null: true do
            authorize permissions
          end
        end
      end

      it 'returns the protected field when user has all permissions' do
        permit(*permission_collection)

        expect(subject).to eq('name' => test_object.name)
      end

      it 'returns nil when user only has one of the permissions' do
        permit(permission_collection.first)

        expect(subject).to eq('name' => nil)
      end

      it 'returns nil when user only has none of the permissions' do
        expect(subject).to eq('name' => nil)
      end
    end
  end

  describe 'Type authorizations' do
    let(:query_type) do
      query_factory do |query|
        query.field :item, type, null: true, resolve: ->(obj, args, ctx) { test_object }
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
    let(:permission_1) { permission_collection.first }
    let(:permission_2) { permission_collection.last }

    let(:type) do
      type_factory do |type|
        type.authorize permission_1
      end
    end

    let(:query_type) do
      query_factory do |query|
        query.field :item, type, null: true, resolve: ->(obj, args, ctx) { test_object }, authorize: permission_2
      end
    end

    include_examples 'authorization with a collection of permissions'
  end

  describe 'type authorizations when applied to a relay connection' do
    let(:query_string) { '{ item() { edges { node { name } } } }' }
    let(:second_test_object) { double(name: 'Second thing') }

    let(:type) do
      type_factory do |type|
        type.authorize permission_single
      end
    end

    let(:query_type) do
      query_factory do |query|
        query.field :item, type.connection_type, null: true, resolve: ->(obj, args, ctx) { [test_object, second_test_object] }
      end
    end

    subject { result.dig('item', 'edges') }

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
          query.field :item, type.connection_type, null: true, resolve: ->(obj, args, ctx) do
            [test_object, second_test_object]
          end
        end
      end

      let(:query_string) { '{ item(first: 1) { edges { node { name } } } }' }

      it 'only checks permissions for the first object' do
        expect(Ability).to receive(:allowed?).with(user, permission_single, test_object) { true }
        expect(Ability).not_to receive(:allowed?).with(user, permission_single, second_test_object)

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
        query.field :item, [type], null: true, resolve: ->(obj, args, ctx) { [test_object] }
      end
    end

    subject { result['item'].first }

    include_examples 'authorization with a single permission'
  end

  describe 'Authorizations on active record relations' do
    let!(:visible_project) { create(:project, :private) }
    let!(:other_project) { create(:project, :private) }
    let!(:visible_issues) { create_list(:issue, 2, project: visible_project) }
    let!(:other_issues) { create_list(:issue, 2, project: other_project) }
    let!(:user) { visible_project.owner }

    let(:issue_type) do
      type_factory do |type|
        type.graphql_name 'FakeIssueType'
        type.authorize :read_issue
        type.field :id, GraphQL::ID_TYPE, null: false
      end
    end
    let(:project_type) do |type|
      type_factory do |type|
        type.graphql_name 'FakeProjectType'
        type.field :test_issues, issue_type.connection_type, null: false, resolve: -> (_, _, _) { Issue.where(project: [visible_project, other_project]) }
      end
    end
    let(:query_type) do
      query_factory do |query|
        query.field :test_project, project_type, null: false, resolve: -> (_, _, _) { visible_project }
      end
    end
    let(:query_string) do
      <<~QRY
        { testProject { testIssues(first: 3) { edges { node { id } } } } }
      QRY
    end

    before do
      allow(Ability).to receive(:allowed?).and_call_original
    end

    it 'renders the issues the user has access to' do
      issue_edges = result['testProject']['testIssues']['edges']
      issue_ids = issue_edges.map { |issue_edge| issue_edge['node']&.fetch('id') }

      expect(issue_edges.size).to eq(visible_issues.size)
      expect(issue_ids).to eq(visible_issues.map { |i| i.to_global_id.to_s })
    end

    it 'does not check access on fields that will not be rendered' do
      expect(Ability).not_to receive(:allowed?).with(user, :read_issue, other_issues.last)

      result
    end
  end

  private

  def permit(*permissions)
    permissions.each do |permission|
      allow(Ability).to receive(:allowed?).with(user, permission, test_object).and_return(true)
    end
  end

  def type_factory
    Class.new(Types::BaseObject) do
      graphql_name 'TestType'

      field :name, GraphQL::STRING_TYPE, null: true

      yield(self) if block_given?
    end
  end

  def query_factory
    Class.new(Types::BaseObject) do
      graphql_name 'TestQuery'

      yield(self) if block_given?
    end
  end

  def execute_query(query_type)
    schema = Class.new(GraphQL::Schema) do
      use Gitlab::Graphql::Authorize
      use Gitlab::Graphql::Connections

      query(query_type)
    end

    schema.execute(
      query_string,
      context: { current_user: user },
      variables: {}
    )
  end
end
