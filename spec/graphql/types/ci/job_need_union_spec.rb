# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::JobNeedUnion, feature_category: :continuous_integration do
  describe '.resolve_type' do
    context 'when resolving a build need' do
      it 'resolves to a BuildNeedType' do
        resolved_type = described_class.resolve_type(build(:ci_build_need), {})

        expect(resolved_type).to be(Types::Ci::BuildNeedType)
      end
    end

    context 'when resolving a build' do
      it 'resolves to a JobType' do
        resolved_type = described_class.resolve_type(build(:ci_build), {})

        expect(resolved_type).to be(Types::Ci::JobType)
      end
    end

    context 'when resolving an unrelated object' do
      it 'raises a TypeNotSupportedError for string object' do
        expect do
          described_class.resolve_type(+'unrelated object', {})
        end.to raise_error(Types::Ci::JobNeedUnion::TypeNotSupportedError)
      end

      it 'raises a TypeNotSupportedError for nil object' do
        expect do
          described_class.resolve_type(nil, {})
        end.to raise_error(Types::Ci::JobNeedUnion::TypeNotSupportedError)
      end

      it 'raises a TypeNotSupportedError for other CI object' do
        expect do
          described_class.resolve_type(build(:ci_pipeline), {})
        end.to raise_error(Types::Ci::JobNeedUnion::TypeNotSupportedError)
      end
    end
  end
end
