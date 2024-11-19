# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CiJobTokenScopeTarget'], feature_category: :secrets_management do
  it 'returns possible types' do
    expect(described_class.possible_types).to include(Types::ProjectType)
    expect(described_class.possible_types).to include(Types::GroupType)
  end

  describe '.resolve_type' do
    it 'resolves projects' do
      object = build(:project)

      expect(described_class.resolve_type(object, {})).to eq(Types::ProjectType)
    end

    it 'resolves groups' do
      object = build(:group)

      expect(described_class.resolve_type(object, {})).to eq(Types::GroupType)
    end

    it 'raises an error when type is not known' do
      expect { described_class.resolve_type(Class, {}) }.to raise_error('Unsupported CI job token scope target type')
    end
  end
end
