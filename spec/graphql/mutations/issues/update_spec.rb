# frozen_string_literal: true

require 'spec_helper'

describe Mutations::Issues::Update do
  let(:issue) { create(:issue) }
  let(:user) { create(:user) }
  let(:expected_attributes) do
    {
      title: 'new title',
      description: 'new description',
      confidential: true,
      due_date: Date.tomorrow
    }
  end
  let(:mutation) { described_class.new(object: nil, context: { current_user: user }, field: nil) }
  let(:mutated_issue) { subject[:issue] }

  specify { expect(described_class).to require_graphql_authorizations(:update_issue) }

  describe '#resolve' do
    let(:mutation_params) do
      {
        project_path: issue.project.full_path,
        iid: issue.iid
      }.merge(expected_attributes)
    end

    subject { mutation.resolve(mutation_params) }

    it 'raises an error if the resource is not accessible to the user' do
      expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
    end

    context 'when the user can update the issue' do
      before do
        issue.project.add_developer(user)
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
    end
  end
end
