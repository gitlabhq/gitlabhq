# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::ResourceLabelEventsFinder, feature_category: :code_review_workflow do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }
  let_it_be(:label) { create(:label, project: project) }
  let_it_be(:other_label) { create(:label, project: project) }

  let_it_be(:label_event) { create(:resource_label_event, merge_request: merge_request, label: label) }
  let_it_be(:other_label_event) { create(:resource_label_event, merge_request: merge_request, label: other_label) }

  describe '#execute' do
    subject(:execute) { described_class.new(merge_request, params).execute }

    context 'without the label_id param' do
      let(:params) { {} }

      it 'returns every label event for the merge request' do
        expect(execute).to contain_exactly(label_event, other_label_event)
      end
    end

    context 'with the label_id param' do
      let(:params) { { label_id: label.id } }

      it 'returns only the events for the given label' do
        expect(execute).to contain_exactly(label_event)
      end
    end

    context 'when the label_id param is nil' do
      let(:params) { { label_id: nil } }

      it 'returns every label event for the merge request' do
        expect(execute).to contain_exactly(label_event, other_label_event)
      end
    end
  end
end
