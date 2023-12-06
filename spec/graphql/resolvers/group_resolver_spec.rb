# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::GroupResolver do
  include GraphqlHelpers

  let_it_be(:group1) { create(:group) }
  let_it_be(:group2) { create(:group) }

  describe '#resolve' do
    it 'batch-resolves groups by full path' do
      paths = [group1.full_path, group2.full_path]

      result = batch_sync(max_queries: 3) do
        paths.map { |path| resolve_group(path) }
      end

      expect(result).to contain_exactly(group1, group2)
    end

    it 'resolves an unknown full_path to nil' do
      result = batch_sync { resolve_group('unknown/group') }

      expect(result).to be_nil
    end

    it 'treats group full path as case insensitive' do
      result = batch_sync { resolve_group(group1.full_path.upcase) }
      expect(result).to eq group1
    end
  end

  def resolve_group(full_path)
    resolve(described_class, args: { full_path: full_path })
  end
end
