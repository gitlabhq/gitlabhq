# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::MutationType do
  it 'is expected to have the MergeRequestSetDraft' do
    expect(described_class).to have_graphql_mutation(Mutations::MergeRequests::SetDraft)
  end

  describe 'deprecated mutations' do
    describe 'clusterAgentTokenDelete' do
      let(:field) { get_field('clusterAgentTokenDelete') }

      it { expect(field.deprecation_reason).to eq('Tokens must be revoked with ClusterAgentTokenRevoke. Deprecated in 14.7.') }
    end
  end

  def get_field(name)
    described_class.fields[GraphqlHelpers.fieldnamerize(name)]
  end
end
