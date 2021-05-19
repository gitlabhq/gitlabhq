# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::DesignManagement::Version::DesignsAtVersionResolver do
  include GraphqlHelpers

  include_context 'four designs in three versions'

  let_it_be(:current_user) { authorized_user }

  let(:gql_context) { { current_user: current_user } }

  let(:version) { third_version }

  describe '.single' do
    let(:single) { ::Resolvers::DesignManagement::Version::DesignAtVersionResolver }

    it 'returns the single context resolver' do
      expect(described_class.single).to eq(single)
    end
  end

  describe '#resolve' do
    let(:args) { {} }

    context 'when the user cannot see designs' do
      let(:current_user) { create(:user) }

      it 'returns nothing' do
        expect(resolve_objects).to be_empty
      end
    end

    context 'for the current version' do
      it 'returns all designs visible at that version' do
        expect(resolve_objects).to contain_exactly(dav(design_a), dav(design_b), dav(design_c))
      end
    end

    context 'for a previous version with more objects' do
      let(:version) { second_version }

      it 'returns objects that were later deleted' do
        expect(resolve_objects).to contain_exactly(dav(design_a), dav(design_b), dav(design_c), dav(design_d))
      end
    end

    context 'for a previous version with fewer objects' do
      let(:version) { first_version }

      it 'does not return objects that were later created' do
        expect(resolve_objects).to contain_exactly(dav(design_a))
      end
    end

    describe 'filtering' do
      describe 'by filename' do
        let(:red_herring) { create(:design, issue: create(:issue, project: project)) }
        let(:args) { { filenames: [design_b.filename, red_herring.filename] } }

        it 'resolves to just the relevant design' do
          create(:design, issue: create(:issue, project: project), filename: design_b.filename)

          expect(resolve_objects).to contain_exactly(dav(design_b))
        end
      end

      describe 'by id' do
        let(:red_herring) { create(:design, issue: create(:issue, project: project)) }
        let(:args) { { ids: [design_a, red_herring].map { |x| global_id_of(x) } } }

        it 'resolves to just the relevant design, ignoring objects on other issues' do
          expect(resolve_objects).to contain_exactly(dav(design_a))
        end
      end
    end
  end

  def resolve_objects
    resolve(described_class, obj: version, args: args, ctx: gql_context)
  end

  def dav(design)
    build(:design_at_version, design: design, version: version)
  end
end
