# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ResolvesGroups do
  include GraphqlHelpers
  include AfterNextHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:groups) { create_pair(:group) }

  let_it_be(:resolver) do
    Class.new(Resolvers::BaseResolver) do
      include ResolvesGroups
      type Types::GroupType, null: true
    end
  end

  let_it_be(:query_type) do
    query_factory do |query|
      query.field :groups,
                  Types::GroupType.connection_type,
                  null: true,
                  resolver: resolver
    end
  end

  let_it_be(:lookahead_fields) do
    <<~FIELDS
      containerRepositoriesCount
      customEmoji { nodes { id } }
      fullPath
      path
      dependencyProxyBlobCount
      dependencyProxyBlobs { nodes { fileName } }
      dependencyProxyImageCount
      dependencyProxyImageTtlPolicy { enabled }
      dependencyProxySetting { enabled }
    FIELDS
  end

  it 'avoids N+1 queries on the fields marked with lookahead' do
    group_ids = groups.map(&:id)

    allow_next(resolver).to receive(:resolve_groups).and_return(Group.id_in(group_ids))
    # Prevent authorization queries from affecting the test.
    allow(Ability).to receive(:allowed?).and_return(true)

    single_group_query = ActiveRecord::QueryRecorder.new do
      data = query_groups(limit: 1)
      expect(data.size).to eq(1)
    end

    multi_group_query = -> {
      data = query_groups(limit: 2)
      expect(data.size).to eq(2)
    }

    expect { multi_group_query.call }.not_to exceed_query_limit(single_group_query)
  end

  def query_groups(limit:)
    query_string = "{ groups(first: #{limit}) { nodes { id #{lookahead_fields} } } }"

    data = execute_query(query_type, graphql: query_string)

    graphql_dig_at(data, :data, :groups, :nodes)
  end
end
