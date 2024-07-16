# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::ProjectResolver do
  include GraphqlHelpers

  it_behaves_like 'a resolver that batch resolves by full path' do
    let_it_be(:entity1) { create(:project) }
    let_it_be(:entity2) { create(:project) }
    let_it_be(:resolve_method) { :resolve_project }
  end

  it 'does not increase complexity depending on number of load limits' do
    field1 = Types::BaseField.new(name: 'test', type: GraphQL::Types::String, resolver_class: described_class, null: false, max_page_size: 100)
    field2 = Types::BaseField.new(name: 'test', type: GraphQL::Types::String, resolver_class: described_class, null: false, max_page_size: 1)

    expect(field1.complexity.call({}, {}, 1)).to eq 2
    expect(field2.complexity.call({}, {}, 1)).to eq 2
  end

  def resolve_project(full_path)
    resolve(described_class, args: { full_path: full_path })
  end
end
