# frozen_string_literal: true

require 'spec_helper'

describe 'Gitlab::Graphql::Authorization' do
  set(:user) { create(:user) }

  let(:test_object) { double(name: 'My name') }
  let(:object_type) { object_type_class }
  let(:query_type) { query_type_class(object_type, test_object) }
  let(:schema) { schema_class(query_type) }

  let(:execute) do
    schema.execute(
      query_string,
      context: { current_user: user },
      variables: {}
    )
  end

  let(:result) { execute['data'] }

  before do
    # By default, disallow all permissions.
    allow(Ability).to receive(:allowed?).and_return(false)
  end

  describe 'authorizing with a single permission' do
    let(:query_string) { '{ singlePermission() { name } }' }

    subject { result['singlePermission'] }

    it 'should return the protected field when user has permission' do
      permit(:foo)

      expect(subject['name']).to eq(test_object.name)
    end

    it 'should return nil when user is not authorized' do
      expect(subject).to be_nil
    end
  end

  describe 'authorizing with an Array of permissions' do
    let(:query_string) { '{ permissionCollection() { name } }' }

    subject { result['permissionCollection'] }

    it 'should return the protected field when user has all permissions' do
      permit(:foo, :bar)

      expect(subject['name']).to eq(test_object.name)
    end

    it 'should return nil when user only has one of the permissions' do
      permit(:foo)

      expect(subject).to be_nil
    end

    it 'should return nil when user only has none of the permissions' do
      expect(subject).to be_nil
    end
  end

  private

  def permit(*permissions)
    permissions.each do |permission|
      allow(Ability).to receive(:allowed?).with(user, permission, test_object).and_return(true)
    end
  end

  def object_type_class
    Class.new(Types::BaseObject) do
      graphql_name 'TestObject'

      field :name, GraphQL::STRING_TYPE, null: true
    end
  end

  def query_type_class(type, object)
    Class.new(Types::BaseObject) do
      graphql_name 'TestQuery'

      field :single_permission, type,
        null: true,
        authorize: :foo,
        resolve: ->(obj, args, ctx) { object }

      field :permission_collection, type,
        null: true,
        resolve: ->(obj, args, ctx) { object } do
        authorize [:foo, :bar]
      end
    end
  end

  def schema_class(query)
    Class.new(GraphQL::Schema) do
      use Gitlab::Graphql::Authorize

      query(query)
    end
  end
end
