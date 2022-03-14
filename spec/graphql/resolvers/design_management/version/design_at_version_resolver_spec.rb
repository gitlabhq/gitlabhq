# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::DesignManagement::Version::DesignAtVersionResolver do
  include GraphqlHelpers

  include_context 'four designs in three versions'

  let(:current_user) { authorized_user }
  let(:gql_context) { { current_user: current_user } }

  let(:version) { third_version }
  let(:design) { design_a }

  let(:all_singular_args) do
    {
      id: global_id_of(dav(design)),
      design_id: global_id_of(design),
      filename: design.filename
    }
  end

  shared_examples 'a bad argument' do
    let(:err_class) { ::Gitlab::Graphql::Errors::ArgumentError }

    it 'generates an error' do
      expect_graphql_error_to_be_created(err_class) do
        resolve_objects
      end
    end
  end

  describe '#resolve' do
    describe 'passing combinations of arguments' do
      context 'passing no arguments' do
        let(:args) { {} }

        it_behaves_like 'a bad argument'
      end

      context 'passing all arguments' do
        let(:args) { all_singular_args }

        it_behaves_like 'a bad argument'
      end

      context 'passing any two arguments' do
        let(:args) { all_singular_args.slice(*all_singular_args.keys.sample(2)) }

        it_behaves_like 'a bad argument'
      end
    end

    %i[id design_id filename].each do |arg|
      describe "passing #{arg}" do
        let(:args) { all_singular_args.slice(arg) }

        it 'finds the design' do
          expect(resolve_objects).to eq(dav(design))
        end

        context 'when the user cannot see designs' do
          let(:current_user) { create(:user) }

          it 'returns nothing' do
            expect(resolve_objects).to be_nil
          end
        end
      end
    end

    describe 'attempting to retrieve an object not visible at this version' do
      let(:design) { design_d }

      %i[id design_id filename].each do |arg|
        describe "passing #{arg}" do
          let(:args) { all_singular_args.slice(arg) }

          it 'does not find the design' do
            expect(resolve_objects).to be_nil
          end
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
