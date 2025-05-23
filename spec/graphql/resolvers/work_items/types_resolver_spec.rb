# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::WorkItems::TypesResolver, feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group, developers: current_user) }
  let_it_be(:project) { create(:project, group: group) }

  let(:args) { {} }

  let(:result) { resolve(described_class, obj: object, args: args) }

  subject(:types_list) { result.map(&:base_type) }

  shared_examples 'arguments validation' do
    context 'when passing multiple arguments' do
      let(:args) { { name: 'ISSUE', list_all: true } }

      it 'raises an error' do
        expect_graphql_error_to_be_created(
          GraphQL::Schema::Validator::ValidationFailedError,
          'Only one of [name, listAll] arguments is allowed at the same time.') do
          result
        end
      end
    end
  end

  shared_examples 'filtering by name' do |existing:, non_existing:|
    context 'when filtering by name' do
      context 'and the type is found' do
        let(:args) { { name: existing.upcase } }

        it { expect(types_list).to eq([existing.downcase]) }
      end

      context 'and the type is not found' do
        let(:args) { { name: non_existing.upcase } }

        it { expect(types_list).to be_empty }
      end
    end
  end

  describe '#resolve' do
    context 'when parent is a group' do
      let(:object) { group }

      it_behaves_like 'arguments validation'

      it_behaves_like 'allowed work item types for a group'

      it_behaves_like 'lists all work item type values' do
        let(:args) { { list_all: true } }
      end

      it_behaves_like 'filtering work item types by existing name' do
        let(:name) { 'issue' }
        let(:args) { { name: name } }
      end
    end

    context 'when parent is a project' do
      let(:object) { project }

      it_behaves_like 'arguments validation'

      it_behaves_like 'allowed work item types for a project'

      it_behaves_like 'lists all work item type values' do
        let(:args) { { list_all: true } }
      end

      it_behaves_like 'filtering work item types by existing name' do
        let(:name) { 'issue' }
        let(:args) { { name: name } }
      end
    end
  end
end
