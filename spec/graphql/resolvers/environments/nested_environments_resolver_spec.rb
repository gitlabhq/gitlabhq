# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Environments::NestedEnvironmentsResolver, feature_category: :continuous_delivery do
  include GraphqlHelpers
  include Gitlab::Graphql::Laziness

  let_it_be(:project) { create(:project, :repository, :private) }
  let_it_be(:environment) { create(:environment, project: project, name: 'test') }
  let_it_be(:environment2) { create(:environment, project: project, name: 'folder1/test') }
  let_it_be(:environment3) { create(:environment, project: project, name: 'folder1/test2') }
  let_it_be(:environment4) { create(:environment, project: project, name: 'folder2/test') }

  let_it_be(:developer) { create(:user, developer_of: project) }

  let(:current_user) { developer }

  describe '#resolve' do
    it 'finds the nested environments when status matches' do
      expect(resolve_nested_environments(status: :created).to_a.pluck(:name, :size))
        .to match_array([
          ['test', 1],
                          ['folder1', 2],
                          ['folder2', 1]
        ])
    end

    it 'finds the nested environments when searching by name' do
      expect(resolve_nested_environments(search: 'folder2').to_a.pluck(:name, :size))
        .to match_array([
          ['folder2', 1]
        ])
    end

    it 'finds the nested environments when name matches exactly' do
      expect(resolve_nested_environments(name: 'test').to_a.pluck(:name, :size))
        .to match_array([
          ['test', 1]
        ])
    end
  end

  def resolve_nested_environments(args = {}, context = { current_user: current_user })
    resolve(described_class, obj: project, ctx: context, args: args)
  end
end
