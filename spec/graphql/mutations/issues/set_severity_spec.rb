# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Issues::SetSeverity do
  let_it_be(:user) { create(:user) }
  let_it_be(:issue) { create(:incident) }

  let(:mutation) { described_class.new(object: nil, context: { current_user: user }, field: nil) }

  specify { expect(described_class).to require_graphql_authorizations(:update_issue) }

  describe '#resolve' do
    let(:severity) { 'critical' }
    let(:mutated_incident) { subject[:issue] }

    subject(:resolve) { mutation.resolve(project_path: issue.project.full_path, iid: issue.iid, severity: severity) }

    it_behaves_like 'permission level for issue mutation is correctly verified'

    context 'when the user can update the issue' do
      before do
        issue.project.add_developer(user)
      end

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
        let!(:issue) { create(:issue) }

        it 'does not updates the issue' do
          expect { resolve }.not_to change { issue.updated_at }
        end
      end
    end
  end
end
