# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Ci::Catalog::Resources::VersionsResolver, feature_category: :pipeline_composition do
  include GraphqlHelpers

  include_context 'when there are catalog resources with versions'

  let(:sort) { nil }
  let(:args) { { sort: sort }.compact }
  let(:ctx) { { current_user: current_user } }

  subject(:result) { resolve(described_class, ctx: ctx, obj: resource1, args: args) }

  describe '#resolve' do
    context 'when the user is authorized to read project releases' do
      before_all do
        resource1.project.add_guest(current_user)
      end

      context 'when sort argument is not provided' do
        it 'returns versions ordered by released_at descending' do
          expect(result.items).to eq([v1_1, v1_0])
        end
      end

      context 'when sort argument is provided' do
        context 'when sort is CREATED_ASC' do
          let(:sort) { 'CREATED_ASC' }

          it 'returns versions ordered by created_at ascending' do
            expect(result.items.to_a).to eq([v1_1, v1_0])
          end
        end

        context 'when sort is CREATED_DESC' do
          let(:sort) { 'CREATED_DESC' }

          it 'returns versions ordered by created_at descending' do
            expect(result.items).to eq([v1_0, v1_1])
          end
        end

        context 'when sort is RELEASED_AT_ASC' do
          let(:sort) { 'RELEASED_AT_ASC' }

          it 'returns versions ordered by released_at ascending' do
            expect(result.items).to eq([v1_0, v1_1])
          end
        end

        context 'when sort is RELEASED_AT_DESC' do
          let(:sort) { 'RELEASED_AT_DESC' }

          it 'returns versions ordered by released_at descending' do
            expect(result.items).to eq([v1_1, v1_0])
          end
        end
      end
    end

    context 'when the user is not authorized to read project releases' do
      it 'returns empty response' do
        expect(result).to be_empty
      end
    end
  end
end
