# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Users::SavedReplies::Create, feature_category: :code_review_workflow do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }

  let(:mutation) { described_class.new(object: nil, context: query_context, field: nil) }

  let(:mutation_arguments) { { name: 'save_reply_name', content: 'Save Reply Content' } }

  describe '#resolve' do
    subject(:resolve) do
      mutation.resolve(**mutation_arguments)
    end

    context 'when service fails to create a new saved reply' do
      let(:mutation_arguments) { { name: '', content: '' } }

      it { expect(resolve[:saved_reply]).to be_nil }
      it { expect(resolve[:errors]).to match_array(["Content can't be blank", "Name can't be blank"]) }
    end

    context 'when service successfully creates a new saved reply' do
      it { expect(resolve[:saved_reply].name).to eq(mutation_arguments[:name]) }
      it { expect(resolve[:saved_reply].content).to eq(mutation_arguments[:content]) }
      it { expect(resolve[:errors]).to be_empty }
    end
  end
end
