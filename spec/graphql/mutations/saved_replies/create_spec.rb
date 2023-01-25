# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::SavedReplies::Create do
  let_it_be(:current_user) { create(:user) }

  let(:mutation) { described_class.new(object: nil, context: { current_user: current_user }, field: nil) }

  let(:mutation_arguments) { { name: 'save_reply_name', content: 'Save Reply Content' } }

  describe '#resolve' do
    subject(:resolve) do
      mutation.resolve(**mutation_arguments)
    end

    context 'when feature is disabled' do
      before do
        stub_feature_flags(saved_replies: false)
      end

      it 'raises Gitlab::Graphql::Errors::ResourceNotAvailable' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable, 'Feature disabled')
      end
    end

    context 'when feature is enabled for current user' do
      before do
        stub_feature_flags(saved_replies: current_user)
      end

      context 'when service fails to create a new saved reply' do
        let(:mutation_arguments) { { name: '', content: '' } }

        it { expect(subject[:saved_reply]).to be_nil }
        it { expect(subject[:errors]).to match_array(["Content can't be blank", "Name can't be blank"]) }
      end

      context 'when service successfully creates a new saved reply' do
        it { expect(subject[:saved_reply].name).to eq(mutation_arguments[:name]) }
        it { expect(subject[:saved_reply].content).to eq(mutation_arguments[:content]) }
        it { expect(subject[:errors]).to be_empty }
      end
    end
  end
end
