# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Issues::Create do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:assignee1) { create(:user) }
  let_it_be(:assignee2) { create(:user) }
  let_it_be(:project_label1) { create(:label, project: project) }
  let_it_be(:project_label2) { create(:label, project: project) }
  let_it_be(:milestone) { create(:milestone, project: project) }
  let_it_be(:new_label1) { FFaker::Lorem.word }
  let_it_be(:new_label2) { new_label1 + 'Extra' }

  let(:expected_attributes) do
    {
      title: 'new title',
      description: 'new description',
      confidential: true,
      due_date: Date.tomorrow,
      discussion_locked: true,
      issue_type: 'issue'
    }
  end

  let(:mutation_params) do
    {
      project_path: project.full_path,
      milestone_id: milestone.to_global_id,
      labels: [project_label1.title, project_label2.title, new_label1, new_label2],
      assignee_ids: [assignee1.to_global_id, assignee2.to_global_id]
    }.merge(expected_attributes)
  end

  let(:special_params) do
    {
      iid: non_existing_record_id,
      created_at: 2.days.ago
    }
  end

  let(:mutation) { described_class.new(object: nil, context: { current_user: user }, field: nil) }
  let(:mutated_issue) { subject[:issue] }

  specify { expect(described_class).to require_graphql_authorizations(:create_issue) }

  describe '#resolve' do
    before do
      stub_licensed_features(multiple_issue_assignees: false, issue_weights: false)
      project.add_guest(assignee1)
      project.add_guest(assignee2)
      stub_spam_services
    end

    subject { mutation.resolve(**mutation_params) }

    context 'when the user does not have permission to create an issue' do
      it 'raises an error' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when the user can create an issue' do
      context 'when creating an issue a developer' do
        before do
          project.add_developer(user)
        end

        it 'creates issue with correct values' do
          expect(mutated_issue).to have_attributes(expected_attributes)
          expect(mutated_issue.milestone_id).to eq(milestone.id)
          expect(mutated_issue.labels.pluck(:title)).to eq([project_label1.title, project_label2.title, new_label1, new_label2])
          expect(mutated_issue.assignees.pluck(:id)).to eq([assignee1.id])
        end

        context 'when passing in label_ids' do
          before do
            mutation_params.delete(:labels)
            mutation_params.merge!(label_ids: [project_label1.to_global_id, project_label2.to_global_id])
          end

          it 'creates issue with correct values' do
            expect(mutated_issue.labels.pluck(:title)).to eq([project_label1.title, project_label2.title])
          end
        end

        context 'when trying to create issue with restricted params' do
          before do
            mutation_params.merge!(special_params)
          end

          it 'ignores the special params' do
            expect(mutated_issue).not_to be_like_time(special_params[:created_at])
            expect(mutated_issue.iid).not_to eq(special_params[:iid])
          end
        end

        context 'when creating a non-default issue type' do
          before do
            mutation_params[:issue_type] = 'incident'
          end

          it 'creates issue with correct values' do
            expect(mutated_issue.issue_type).to eq('incident')
          end
        end
      end

      context 'when creating an issue as owner' do
        let_it_be(:user) { project.owner }

        before do
          mutation_params.merge!(special_params)
        end

        it 'sets the special params' do
          expect(mutated_issue.created_at).to be_like_time(special_params[:created_at])
          expect(mutated_issue.iid).to eq(special_params[:iid])
        end
      end
    end
  end

  describe "#ready?" do
    context 'when passing in both labels and label_ids' do
      before do
        mutation_params.merge!(label_ids: [project_label1.to_global_id, project_label2.to_global_id])
      end

      it 'raises exception when mutually exclusive params are given' do
        expect { mutation.ready?(**mutation_params) }
          .to raise_error(Gitlab::Graphql::Errors::ArgumentError, /one and only one of/)
      end
    end

    context 'when passing only `discussion_to_resolve` param' do
      before do
        mutation_params.merge!(discussion_to_resolve: 'abc')
      end

      it 'raises exception when mutually exclusive params are given' do
        expect { mutation.ready?(**mutation_params) }
          .to raise_error(Gitlab::Graphql::Errors::ArgumentError, /to resolve a discussion please also provide `merge_request_to_resolve_discussions_of` parameter/)
      end
    end

    context 'when passing only `merge_request_to_resolve_discussions_of` param' do
      before do
        mutation_params.merge!(merge_request_to_resolve_discussions_of: 'abc')
      end

      it 'raises exception when mutually exclusive params are given' do
        expect { mutation.ready?(**mutation_params) }.not_to raise_error
      end
    end
  end
end
