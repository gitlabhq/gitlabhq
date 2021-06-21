# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Issues::Update do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:project_label) { create(:label, project: project) }
  let_it_be(:issue) { create(:issue, project: project, labels: [project_label]) }
  let_it_be(:milestone) { create(:milestone, project: project) }

  let(:expected_attributes) do
    {
      title: 'new title',
      description: 'new description',
      confidential: true,
      due_date: Date.tomorrow,
      discussion_locked: true,
      milestone_id: milestone.id
    }
  end

  let(:mutation) { described_class.new(object: nil, context: { current_user: user }, field: nil) }
  let(:mutated_issue) { subject[:issue] }

  specify { expect(described_class).to require_graphql_authorizations(:update_issue) }

  describe '#resolve' do
    let(:mutation_params) do
      {
        project_path: project.full_path,
        iid: issue.iid
      }.merge(expected_attributes)
    end

    subject { mutation.resolve(**mutation_params) }

    before do
      stub_spam_services
    end

    it_behaves_like 'permission level for issue mutation is correctly verified'

    context 'when the user can update the issue' do
      before do
        project.add_developer(user)
      end

      it 'updates issue with correct values' do
        subject

        expect(issue.reload).to have_attributes(expected_attributes)
      end

      context 'when iid does not exist' do
        it 'raises resource not available error' do
          mutation_params[:iid] = non_existing_record_iid

          expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        end
      end

      context 'when setting milestone to nil' do
        let(:expected_attributes) { { milestone_id: nil } }

        it 'changes the milestone corrrectly' do
          issue.update_column(:milestone_id, milestone.id)

          expect { subject }.to change { issue.reload.milestone }.from(milestone).to(nil)
        end
      end

      context 'when changing state' do
        let_it_be_with_refind(:issue) { create(:issue, project: project, state: :opened) }

        it 'closes issue' do
          mutation_params[:state_event] = 'close'

          expect { subject }.to change { issue.reload.state }.from('opened').to('closed')
        end

        it 'reopens issue' do
          issue.close
          mutation_params[:state_event] = 'reopen'

          expect { subject }.to change { issue.reload.state }.from('closed').to('opened')
        end
      end

      context 'when changing labels' do
        let_it_be(:label_1) { create(:label, project: project) }
        let_it_be(:label_2) { create(:label, project: project) }
        let_it_be(:external_label) { create(:label, project: create(:project)) }

        it 'adds and removes labels correctly' do
          mutation_params[:add_label_ids] = [label_1.id, label_2.id]
          mutation_params[:remove_label_ids] = [project_label.id]

          subject

          expect(issue.reload.labels).to match_array([label_1, label_2])
        end

        it 'does not add label if label id is nil' do
          mutation_params[:add_label_ids] = [nil, label_2.id]

          subject

          expect(issue.reload.labels).to match_array([project_label, label_2])
        end

        it 'does not add label if label is not found' do
          mutation_params[:add_label_ids] = [external_label.id, label_2.id]

          subject

          expect(issue.reload.labels).to match_array([project_label, label_2])
        end

        it 'does not modify labels if label is already present' do
          mutation_params[:add_label_ids] = [project_label.id]

          expect(issue.reload.labels).to match_array([project_label])
        end

        it 'does not modify labels if label is addded and removed in the same request' do
          mutation_params[:add_label_ids] = [label_1.id, label_2.id]
          mutation_params[:remove_label_ids] = [label_1.id]

          subject

          expect(issue.reload.labels).to match_array([project_label, label_2])
        end
      end

      context 'when changing type' do
        it 'changes the type of the issue' do
          mutation_params[:issue_type] = 'incident'

          expect { subject }.to change { issue.reload.issue_type }.from('issue').to('incident')
        end
      end
    end
  end
end
