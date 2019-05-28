# frozen_string_literal: true

require 'spec_helper'

describe Resolvers::GroupResolver do
  include GraphqlHelpers

  set(:group1) { create(:group) }
  set(:group2) { create(:group) }

  describe '#resolve' do
    it 'batch-resolves groups by full path' do
      paths = [group1.full_path, group2.full_path]

      result = batch(max_queries: 1) do
        paths.map { |path| resolve_group(path) }
      end

      expect(result).to contain_exactly(group1, group2)
    end

    it 'resolves an unknown full_path to nil' do
      result = batch { resolve_group('unknown/project') }

      expect(result).to be_nil
    end
  end

  def resolve_group(full_path)
    resolve(described_class, args: { full_path: full_path })
  end
end
