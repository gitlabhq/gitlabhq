# frozen_string_literal: true

require 'spec_helper'

describe Mutations::MergeRequests::SetAssignees do
  let(:merge_request) { create(:merge_request) }
  let(:user) { create(:user) }

  subject(:mutation) { described_class.new(object: nil, context: { current_user: user }) }

  describe '#resolve' do
    let(:assignee) { create(:user) }
    let(:assignee2) { create(:user) }
    let(:assignee_usernames) { [assignee.username] }
    let(:mutated_merge_request) { subject[:merge_request] }

    subject { mutation.resolve(project_path: merge_request.project.full_path, iid: merge_request.iid, assignee_usernames: assignee_usernames) }

    before do
      merge_request.project.add_developer(assignee)
      merge_request.project.add_developer(assignee2)
    end

    it 'raises an error if the resource is not accessible to the user' do
      expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
    end

    context 'when the user can update the merge request' do
      before do
        merge_request.project.add_developer(user)
      end

      it 'replaces the assignee' do
        merge_request.assignees = [assignee2]
        merge_request.save!

        expect(mutated_merge_request).to eq(merge_request)
        expect(mutated_merge_request.assignees).to contain_exactly(assignee)
        expect(subject[:errors]).to be_empty
      end

      it 'returns errors merge request could not be updated' do
        # Make the merge request invalid
        merge_request.allow_broken = true
        merge_request.update!(source_project: nil)

        expect(subject[:errors]).not_to be_empty
      end

      context 'when passing an empty assignee list' do
        let(:assignee_usernames) { [] }

        before do
          merge_request.assignees = [assignee]
          merge_request.save!
        end

        it 'removes all assignees' do
          expect(mutated_merge_request).to eq(merge_request)
          expect(mutated_merge_request.assignees).to eq([])
          expect(subject[:errors]).to be_empty
        end
      end

      context 'when passing "append" as true' do
        subject { mutation.resolve(project_path: merge_request.project.full_path, iid: merge_request.iid, assignee_usernames: assignee_usernames, operation_mode: Types::MutationOperationModeEnum.enum[:append]) }

        before do
          merge_request.assignees = [assignee2]
          merge_request.save!

          # In CE, APPEND is a NOOP as you can't have multiple assignees
          # We test multiple assignment in EE specs
          stub_licensed_features(multiple_merge_request_assignees: false)
        end

        it 'is a NO-OP in FOSS' do
          expect(mutated_merge_request).to eq(merge_request)
          expect(mutated_merge_request.assignees).to contain_exactly(assignee2)
          expect(subject[:errors]).to be_empty
        end
      end

      context 'when passing "remove" as true' do
        before do
          merge_request.assignees = [assignee]
          merge_request.save!
        end

        it 'removes named assignee' do
          mutated_merge_request = mutation.resolve(project_path: merge_request.project.full_path, iid: merge_request.iid, assignee_usernames: assignee_usernames, operation_mode: Types::MutationOperationModeEnum.enum[:remove])[:merge_request]

          expect(mutated_merge_request).to eq(merge_request)
          expect(mutated_merge_request.assignees).to eq([])
          expect(subject[:errors]).to be_empty
        end

        it 'does not remove unnamed assignee' do
          mutated_merge_request = mutation.resolve(project_path: merge_request.project.full_path, iid: merge_request.iid, assignee_usernames: [assignee2.username], operation_mode: Types::MutationOperationModeEnum.enum[:remove])[:merge_request]

          expect(mutated_merge_request).to eq(merge_request)
          expect(mutated_merge_request.assignees).to contain_exactly(assignee)
          expect(subject[:errors]).to be_empty
        end
      end
    end
  end
end
