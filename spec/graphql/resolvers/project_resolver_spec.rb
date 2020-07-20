# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::ProjectResolver do
  include GraphqlHelpers

  let_it_be(:project1) { create(:project) }
  let_it_be(:project2) { create(:project) }
  let_it_be(:other_project) { create(:project) }

  describe '#resolve' do
    it 'batch-resolves projects by full path' do
      paths = [project1.full_path, project2.full_path]

      result = batch_sync(max_queries: 1) do
        paths.map { |path| resolve_project(path) }
      end

      expect(result).to contain_exactly(project1, project2)
    end

    it 'resolves an unknown full_path to nil' do
      result = batch_sync { resolve_project('unknown/project') }

      expect(result).to be_nil
    end
  end

  it 'does not increase complexity depending on number of load limits' do
    field1 = Types::BaseField.new(name: 'test', type: GraphQL::STRING_TYPE, resolver_class: described_class, null: false, max_page_size: 100)
    field2 = Types::BaseField.new(name: 'test', type: GraphQL::STRING_TYPE, resolver_class: described_class, null: false, max_page_size: 1)

    expect(field1.to_graphql.complexity.call({}, {}, 1)).to eq 2
    expect(field2.to_graphql.complexity.call({}, {}, 1)).to eq 2
  end

  def resolve_project(full_path)
    resolve(described_class, args: { full_path: full_path })
  end
end
