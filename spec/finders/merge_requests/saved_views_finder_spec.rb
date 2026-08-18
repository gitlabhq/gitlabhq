# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::SavedViewsFinder, feature_category: :code_review_workflow do
  let_it_be(:user) { create(:user) }
  let_it_be(:other_user) { create(:user) }
  let_it_be(:view_b) { create(:merge_request_saved_view, user: user, name: 'B view') }
  let_it_be(:view_a) { create(:merge_request_saved_view, user: user, name: 'A view') }
  let_it_be(:view_c) { create(:merge_request_saved_view, :with_filters, user: user, name: 'C view') }
  let_it_be(:other_users_view) { create(:merge_request_saved_view, user: other_user) }

  let(:current_user) { user }

  subject(:execute) { described_class.new(current_user).execute }

  it "returns only the current user's views" do
    expect(execute).to contain_exactly(view_b, view_a, view_c)
  end

  it 'orders by id ascending, not by name' do
    expect(execute.map(&:name)).to eq(['B view', 'A view', 'C view'])
  end

  context 'when scoped to another user' do
    let(:current_user) { other_user }

    it "returns only that user's views" do
      expect(execute).to contain_exactly(other_users_view)
    end
  end

  context 'when current_user is nil' do
    let(:current_user) { nil }

    it 'returns an empty relation' do
      expect(execute).to be_empty
    end
  end

  context 'when the user has no saved views' do
    let_it_be(:current_user) { create(:user) }

    it 'returns an empty relation' do
      expect(execute).to be_empty
    end
  end
end
