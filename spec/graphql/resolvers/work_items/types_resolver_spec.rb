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

  describe '#resolve' do
    context 'when parent is a group' do
      let(:object) { group }

      it_behaves_like 'lists all work item type values' do
        let(:args) { { only_available: false } }
      end

      it_behaves_like 'lists generally available work item types'

      it_behaves_like 'filtering work item types by existing name' do
        let(:name) { 'issue' }
        let(:args) { { name: name, only_available: false } }
      end

      it_behaves_like 'allowed work item types for a group' do
        let(:args) { { only_available: true } }
      end
    end

    context 'when parent is a project' do
      let(:object) { project }

      it_behaves_like 'lists all work item type values' do
        let(:args) { { only_available: false } }
      end

      it_behaves_like 'lists generally available work item types'

      it_behaves_like 'filtering work item types by existing name' do
        let(:name) { 'issue' }
        let(:args) { { name: name, only_available: false } }
      end

      it_behaves_like 'allowed work item types for a project' do
        let(:args) { { only_available: true } }
      end
    end

    describe 'forwarding `only_available` to the finder' do
      let(:object) { project }
      let(:finder) { instance_double(::WorkItems::TypesFinder) }

      before do
        allow(::WorkItems::TypesFinder).to receive(:new).with(container: object).and_return(finder)
        allow(finder).to receive(:execute).and_return([])
      end

      context 'when only_available is omitted' do
        let(:args) { {} }

        it 'does not pass only_available to the finder' do
          result

          expect(finder).to have_received(:execute).with(name: nil)
        end
      end

      context 'when only_available is true' do
        let(:args) { { only_available: true } }

        it 'forwards only_available: true to the finder' do
          result

          expect(finder).to have_received(:execute).with(name: nil, only_available: true)
        end
      end

      context 'when only_available is false' do
        let(:args) { { only_available: false } }

        it 'forwards only_available: false to the finder' do
          result

          expect(finder).to have_received(:execute).with(name: nil, only_available: false)
        end
      end
    end
  end
end
