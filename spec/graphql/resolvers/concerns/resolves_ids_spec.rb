# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ResolvesIds do
  # gid://gitlab/Project/6
  # gid://gitlab/Issue/6
  # gid://gitlab/Project/6 gid://gitlab/Issue/6
  context 'with a single project' do
    let(:ids) { 'gid://gitlab/Project/6' }
    let(:type) { ::Types::GlobalIDType[::Project] }

    it 'returns the correct array' do
      expect(resolve_ids).to match_array(['6'])
    end
  end

  context 'with a single issue' do
    let(:ids) { 'gid://gitlab/Issue/9' }
    let(:type) { ::Types::GlobalIDType[::Issue] }

    it 'returns the correct array' do
      expect(resolve_ids).to match_array(['9'])
    end
  end

  context 'with multiple users' do
    let(:ids) { ['gid://gitlab/User/7', 'gid://gitlab/User/13', 'gid://gitlab/User/21'] }
    let(:type) { ::Types::GlobalIDType[::User] }

    it 'returns the correct array' do
      expect(resolve_ids).to match_array(%w[7 13 21])
    end
  end

  def mock_resolver
    Class.new(GraphQL::Schema::Resolver) { extend ResolvesIds }
  end

  def resolve_ids
    mock_resolver.resolve_ids(ids, type)
  end
end
