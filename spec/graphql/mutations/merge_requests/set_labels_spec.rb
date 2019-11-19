# frozen_string_literal: true

require 'spec_helper'

describe Mutations::MergeRequests::SetLabels do
  let(:merge_request) { create(:merge_request) }
  let(:user) { create(:user) }
  subject(:mutation) { described_class.new(object: nil, context: { current_user: user }) }

  describe '#resolve' do
    let(:label) { create(:label, project: merge_request.project) }
    let(:label2) { create(:label, project: merge_request.project) }
    let(:label_ids) { [label.to_global_id] }
    let(:mutated_merge_request) { subject[:merge_request] }
    subject { mutation.resolve(project_path: merge_request.project.full_path, iid: merge_request.iid, label_ids: label_ids) }

    it 'raises an error if the resource is not accessible to the user' do
      expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
    end

    context 'when the user can update the merge request' do
      before do
        merge_request.project.add_developer(user)
      end

      it 'sets the labels, removing all others' do
        merge_request.update!(labels: [label2])

        expect(mutated_merge_request).to eq(merge_request)
        expect(mutated_merge_request.labels).to contain_exactly(label)
        expect(subject[:errors]).to be_empty
      end

      it 'returns errors merge request could not be updated' do
        # Make the merge request invalid
        merge_request.allow_broken = true
        merge_request.update!(source_project: nil)

        expect(subject[:errors]).not_to be_empty
      end

      context 'when passing an empty array' do
        let(:label_ids) { [] }

        it 'removes all labels' do
          merge_request.update!(labels: [label])

          expect(mutated_merge_request.labels).to be_empty
        end
      end

      context 'when passing operation_mode as APPEND' do
        subject { mutation.resolve(project_path: merge_request.project.full_path, iid: merge_request.iid, label_ids: label_ids, operation_mode: Types::MutationOperationModeEnum.enum[:append]) }

        it 'sets the labels, without removing others' do
          merge_request.update!(labels: [label2])

          expect(mutated_merge_request).to eq(merge_request)
          expect(mutated_merge_request.labels).to contain_exactly(label, label2)
          expect(subject[:errors]).to be_empty
        end
      end

      context 'when passing operation_mode as REMOVE' do
        subject { mutation.resolve(project_path: merge_request.project.full_path, iid: merge_request.iid, label_ids: label_ids, operation_mode: Types::MutationOperationModeEnum.enum[:remove])}

        it 'removes the labels, without removing others' do
          merge_request.update!(labels: [label, label2])

          expect(mutated_merge_request).to eq(merge_request)
          expect(mutated_merge_request.labels).to contain_exactly(label2)
          expect(subject[:errors]).to be_empty
        end
      end
    end
  end
end
