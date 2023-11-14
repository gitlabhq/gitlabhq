# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::DataTransfer::GroupDataTransferResolver, feature_category: :source_code_management do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:current_user) { create(:user) }

  let(:from) { Date.new(2022, 1, 1) }
  let(:to) { Date.new(2023, 1, 1) }
  let(:finder) { instance_double(::DataTransfer::GroupDataTransferFinder) }
  let(:finder_results) do
    [
      build(:project_data_transfer, date: to, repository_egress: 250000)
    ]
  end

  context 'with anonymous access' do
    let_it_be(:current_user) { nil }

    it 'does not raise an error and returns no data' do
      expect { resolve_egress }.not_to raise_error
      expect(resolve_egress).to be_nil
    end
  end

  context 'with authorized user but without enough permissions' do
    it 'does not raise an error and returns no data' do
      group.add_developer(current_user)

      expect { resolve_egress }.not_to raise_error
      expect(resolve_egress).to be_nil
    end
  end

  context 'when user has permissions to see data transfer' do
    before do
      group.add_owner(current_user)
    end

    include_examples 'Data transfer resolver'

    it 'calls GroupDataTransferFinder with expected arguments' do
      expect(::DataTransfer::GroupDataTransferFinder).to receive(:new).with(
        group: group, from: from, to: to, user: current_user).once.and_return(finder)
      allow(finder).to receive(:execute).once.and_return(finder_results)

      expect(resolve_egress).to eq({ egress_nodes: finder_results.map(&:attributes) })
    end
  end

  def resolve_egress
    resolve(described_class, obj: group, args: { from: from, to: to }, ctx: { current_user: current_user })
  end
end
