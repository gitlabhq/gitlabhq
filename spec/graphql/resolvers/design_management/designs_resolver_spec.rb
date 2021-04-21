# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::DesignManagement::DesignsResolver do
  include GraphqlHelpers
  include DesignManagementTestHelpers

  specify do
    expect(described_class).to have_nullable_graphql_type(::Types::DesignManagement::DesignType.connection_type)
  end

  before do
    enable_design_management
  end

  describe '#resolve' do
    let_it_be(:issue) { create(:issue) }
    let_it_be(:project) { issue.project }
    let_it_be(:first_version) { create(:design_version) }
    let_it_be(:first_design) { create(:design, issue: issue, versions: [first_version]) }
    let_it_be(:current_user) { create(:user) }

    let(:gql_context) { { current_user: current_user } }
    let(:args) { {} }

    before do
      project.add_developer(current_user)
    end

    context 'when the user cannot see designs' do
      let(:gql_context) { { current_user: create(:user) } }

      it 'returns nothing' do
        expect(resolve_designs).to be_empty
      end
    end

    context 'for a design collection' do
      context 'which contains just a single design' do
        it 'returns just that design' do
          expect(resolve_designs).to contain_exactly(first_design)
        end
      end

      context 'which contains another design' do
        it 'returns all designs' do
          second_version = create(:design_version)
          second_design = create(:design, issue: issue, versions: [second_version])

          expect(resolve_designs).to contain_exactly(first_design, second_design)
        end
      end
    end

    describe 'filtering' do
      describe 'by filename' do
        let(:second_version) { create(:design_version) }
        let(:second_design) { create(:design, issue: issue, versions: [second_version]) }
        let(:args) { { filenames: [second_design.filename] } }

        it 'resolves to just the relevant design, ignoring designs with the same filename on different issues' do
          create(:design, issue: create(:issue, project: project), filename: second_design.filename)

          expect(resolve_designs).to contain_exactly(second_design)
        end
      end

      describe 'by id' do
        let(:second_version) { create(:design_version) }
        let(:second_design) { create(:design, issue: issue, versions: [second_version]) }

        context 'ids is provided but null' do
          let(:args) { { ids: nil } }

          it 'behaves as if unfiltered' do
            expect(resolve_designs).to contain_exactly(first_design, second_design)
          end
        end

        context 'ids is provided but empty' do
          let(:args) { { ids: [] } }

          it 'eliminates all values' do
            expect(resolve_designs).to be_empty
          end
        end

        context 'the ID is on the current issue' do
          let(:args) { { ids: [GitlabSchema.id_from_object(second_design)] } }

          it 'resolves to just the relevant design' do
            expect(resolve_designs).to contain_exactly(second_design)
          end
        end

        context 'the ID is on a different issue' do
          let(:third_version) { create(:design_version) }
          let(:third_design) { create(:design, issue: create(:issue, project: project), versions: [third_version]) }

          let(:args) { { ids: [GitlabSchema.id_from_object(third_design)] } }

          it 'ignores it' do
            expect(resolve_designs).to be_empty
          end
        end
      end
    end
  end

  def resolve_designs
    resolve(described_class, obj: issue.design_collection, args: args, ctx: gql_context)
  end
end
