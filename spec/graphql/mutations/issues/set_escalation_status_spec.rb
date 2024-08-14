# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Issues::SetEscalationStatus, feature_category: :api do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:issue, reload: true) { create(:incident, project: project) }
  let_it_be(:escalation_status, reload: true) { create(:incident_management_issuable_escalation_status, issue: issue) }

  let(:status) { :acknowledged }
  let(:mutation) { described_class.new(object: nil, context: query_context, field: nil) }

  describe '#resolve' do
    let(:args) { { status: status } }
    let(:mutated_issue) { result[:issue] }

    subject(:result) { mutation.resolve(project_path: issue.project.full_path, iid: issue.iid, **args) }

    it_behaves_like 'permission level for issue mutation is correctly verified', true

    context 'when the user can update the issue' do
      before_all do
        project.add_reporter(current_user)
      end

      it_behaves_like 'permission level for issue mutation is correctly verified', true

      context 'when the user can update the escalation status' do
        before_all do
          project.add_developer(current_user)
        end

        it 'returns the issue with the escalation policy' do
          expect(mutated_issue).to eq(issue)
          expect(mutated_issue.escalation_status.status_name).to eq(status)
          expect(result[:errors]).to be_empty
        end

        it 'returns errors when issue update fails' do
          issue.update_column(:author_id, nil)

          expect(result[:errors]).not_to be_empty
        end

        context 'with non-incident issue is provided' do
          let_it_be(:issue) { create(:issue, project: project) }

          it 'raises an error' do
            expect { result }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable, 'Feature unavailable for provided issue')
          end
        end
      end
    end
  end
end
