# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Issues::SetLocked, feature_category: :api do
  include GraphqlHelpers

  let_it_be(:issue) { create(:issue) }
  let_it_be(:current_user) { create(:user) }

  subject(:mutation) { described_class.new(object: nil, context: query_context, field: nil) }

  specify { expect(described_class).to require_graphql_authorizations(:update_issue) }

  describe '#resolve' do
    let(:locked) { true }

    subject { mutation.resolve(project_path: issue.project.full_path, iid: issue.iid, locked: locked) }

    it_behaves_like 'permission level for issue mutation is correctly verified'

    context 'when the user can update the issue' do
      let(:mutated_issue) { subject[:issue] }

      before do
        issue.project.add_developer(current_user)
      end

      it 'returns the issue as discussion locked' do
        expect(mutated_issue).to eq(issue)
        expect(mutated_issue).to be_discussion_locked
        expect(subject[:errors]).to be_empty
      end

      context 'when passing locked as false' do
        let(:locked) { false }

        it 'unlocks the discussion' do
          issue.update!(discussion_locked: true)

          expect(mutated_issue).not_to be_discussion_locked
        end
      end
    end
  end
end
