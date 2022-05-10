# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ResolvesIds do
  include GraphqlHelpers

  # gid://gitlab/Project/6
  # gid://gitlab/Issue/6
  # gid://gitlab/Project/6 gid://gitlab/Issue/6
  context 'with a single project' do
    let(:ids) { global_id_of(model_name: 'Project', id: 6) }

    it 'returns the correct array' do
      expect(resolve_ids).to contain_exactly('6')
    end
  end

  context 'with a single issue' do
    let(:ids) { global_id_of(model_name: 'Issue', id: 9) }

    it 'returns the correct array' do
      expect(resolve_ids).to contain_exactly('9')
    end
  end

  context 'with multiple users' do
    let(:ids) { [7, 13, 21].map { global_id_of(model_name: 'User', id: _1) } }

    it 'returns the correct array' do
      expect(resolve_ids).to eq %w[7 13 21]
    end
  end

  def mock_resolver
    Class.new(GraphQL::Schema::Resolver) { extend ResolvesIds }
  end

  def resolve_ids
    mock_resolver.resolve_ids(ids)
  end
end
