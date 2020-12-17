# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::FindsByGid do
  include GraphqlHelpers

  let(:mutation_class) do
    Class.new(Mutations::BaseMutation) do
      authorize :read_user

      include Mutations::FindsByGid
    end
  end

  let(:query) { double('Query', schema: GitlabSchema) }
  let(:context) { GraphQL::Query::Context.new(query: query, object: nil, values: { current_user: user }) }
  let(:user) { create(:user) }
  let(:gid) { user.to_global_id }

  subject(:mutation) { mutation_class.new(object: nil, context: context, field: nil) }

  it 'calls GitlabSchema.find_by_gid to find objects during authorized_find!' do
    expect(mutation.authorized_find!(id: gid)).to eq(user)
  end
end
