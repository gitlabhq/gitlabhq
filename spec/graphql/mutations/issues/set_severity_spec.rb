# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Issues::SetSeverity, feature_category: :api do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:guest) { create(:user, guest_of: project) }
  let_it_be(:reporter) { create(:user, reporter_of: project) }
  let_it_be(:issue) { create(:incident, project: project) }

  let(:mutation) { described_class.new(object: nil, context: query_context, field: nil) }

  specify { expect(described_class).to require_graphql_authorizations(:update_issue, :admin_issue) }

  describe '#resolve' do
    let(:severity) { 'critical' }

    subject(:resolve) do
      mutation.resolve(
        project_path: issue.project.full_path,
        iid: issue.iid,
        severity: severity
      )
    end

    context 'as guest' do
      let(:current_user) { guest }

      it 'raises an error' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end

      context 'and also author' do
        let!(:issue) { create(:incident, project: project, author: current_user) }

        it 'raises an error' do
          expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        end
      end

      context 'and also assignee' do
        let!(:issue) { create(:incident, project: project, assignee_ids: [current_user.id]) }

        it 'raises an error' do
          expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        end
      end
    end

    context 'as reporter' do
      let(:current_user) { reporter }

      context 'when issue type is incident' do
        context 'when severity has a correct value' do
          it 'updates severity' do
            expect(resolve[:issue].severity).to eq('critical')
          end

          it 'returns no errors' do
            expect(resolve[:errors]).to be_empty
          end
        end

        context 'when severity has an unsuported value' do
          let(:severity) { 'unsupported-severity' }

          it 'sets severity to default' do
            expect(resolve[:issue].severity).to eq(IssuableSeverity::DEFAULT)
          end

          it 'returns no errorsr' do
            expect(resolve[:errors]).to be_empty
          end
        end
      end

      context 'when issue type is not incident' do
        let!(:issue) { create(:issue, project: project) }

        it 'does not update the issue' do
          expect { resolve }.not_to change { issue.updated_at }
        end
      end
    end
  end
end
