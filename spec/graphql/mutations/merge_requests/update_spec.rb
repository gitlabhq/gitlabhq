# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::MergeRequests::Update, feature_category: :team_planning do
  include GraphqlHelpers

  let(:merge_request) { create(:merge_request) }
  let(:user) { create(:user) }
  let(:query) { GraphQL::Query.new(empty_schema, document: nil, context: {}, variables: {}) }
  let(:context) { GraphQL::Query::Context.new(query: query, values: { current_user: user }) }

  subject(:mutation) { described_class.new(object: nil, context: context, field: nil) }

  specify { expect(described_class).to require_graphql_authorizations(:update_merge_request) }

  describe '#resolve' do
    let(:attributes) { { title: 'new title', description: 'new description', target_branch: 'new-branch' } }
    let(:arguments) { attributes }
    let(:mutated_merge_request) { subject[:merge_request] }

    subject do
      mutation.resolve(project_path: merge_request.project.full_path, iid: merge_request.iid, **arguments)
    end

    it_behaves_like 'permission level for merge request mutation is correctly verified'

    context 'when the user can update the merge request' do
      before do
        merge_request.project.add_developer(user)
      end

      context 'when all attributes except timeEstimate are provided' do
        before do
          merge_request.update!(time_estimate: 3600)
        end

        it 'applies all attributes' do
          expect(mutated_merge_request).to eq(merge_request)
          expect(mutated_merge_request).to have_attributes(attributes)
          expect(mutated_merge_request.time_estimate).to eq(3600)
          expect(subject[:errors]).to be_empty
        end
      end

      context 'when timeEstimate attribute is provided' do
        let(:time_estimate) { '0' }
        let(:attributes) { { time_estimate: time_estimate } }

        before do
          merge_request.update!(time_estimate: 3600)
        end

        context 'when timeEstimate is invalid' do
          let(:time_estimate) { '1e' }

          it 'changes are not applied' do
            expect { mutation.ready?(time_estimate: time_estimate) }
              .to raise_error(
                Gitlab::Graphql::Errors::ArgumentError,
                'timeEstimate must be formatted correctly, for example `1h 30m`')
            expect(mutated_merge_request.time_estimate).to eq(3600)
          end
        end

        context 'when timeEstimate is negative' do
          let(:time_estimate) { '-1h' }

          it 'raises an argument error and changes are not applied' do
            expect { mutation.ready?(time_estimate: time_estimate) }
            .to raise_error(Gitlab::Graphql::Errors::ArgumentError,
              'timeEstimate must be greater than or equal to zero. ' \
              'Remember that every new timeEstimate overwrites the previous value.')
            expect { subject }.not_to change { merge_request.time_estimate }
          end
        end

        context 'when timeEstimate is 0' do
          let(:time_estimate) { '0' }

          it 'resets the time estimate' do
            expect(mutated_merge_request.time_estimate).to eq(0)
            expect(subject[:errors]).to be_empty
          end
        end

        context 'when timeEstimate is a valid human readable time' do
          let(:time_estimate) { '1h 30m' }

          it 'updates the time estimate' do
            expect(mutated_merge_request.time_estimate).to eq(5400)
            expect(subject[:errors]).to be_empty
          end
        end
      end

      context 'when optional merge_after field is set' do
        let(:attributes) { { merge_after: '2025-01-09T20:47:00+0100' } }

        it 'returns a new merge request with merge_after' do
          expect(mutated_merge_request.merge_schedule.merge_after).to eq('2025-01-09T19:47:00.000Z')
          expect(subject[:errors]).to be_empty
        end
      end

      context 'the merge request is invalid' do
        before do
          merge_request.allow_broken = true
          merge_request.update!(source_project: nil)
        end

        it 'returns error information, and changes were not applied' do
          expect(mutated_merge_request).not_to have_attributes(attributes)
          expect(subject[:errors]).not_to be_empty
        end
      end

      context 'our change is invalid' do
        let(:attributes) { { target_branch: 'this is not a branch' } }

        it 'returns error information, and changes were not applied' do
          expect(mutated_merge_request).not_to have_attributes(attributes)
          expect(subject[:errors]).not_to be_empty
        end
      end

      context 'when passing subset of attributes' do
        let(:attributes) { { title: 'no, this title' } }

        it 'only changes the mentioned attributes' do
          expect { subject }.not_to change { merge_request.reset.description }

          expect(mutated_merge_request).to have_attributes(attributes)
        end
      end

      context 'when closing the MR' do
        let(:arguments) { { state_event: ::Types::MergeRequestStateEventEnum.values['CLOSED'].value } }

        it 'closes the MR' do
          expect(mutated_merge_request).to be_closed
        end
      end

      context 'when re-opening the MR' do
        let(:arguments) { { state_event: ::Types::MergeRequestStateEventEnum.values['OPEN'].value } }

        it 'closes the MR' do
          merge_request.close!

          expect(mutated_merge_request).to be_open
        end
      end
    end
  end

  describe '#ready?' do
    let(:extra_args) { {} }

    let(:arguments) do
      {
        project_path: merge_request.project.full_path,
        iid: merge_request.iid
      }.merge(extra_args)
    end

    subject(:ready) { mutation.ready?(**arguments) }

    context 'when timeEstimate is provided' do
      let(:extra_args) { { time_estimate: time_estimate } }

      context 'when the value is invalid' do
        let(:time_estimate) { '1e' }

        it 'raises an argument error' do
          expect { subject }.to raise_error(
            Gitlab::Graphql::Errors::ArgumentError,
            'timeEstimate must be formatted correctly, for example `1h 30m`')
        end
      end

      context 'when the value valid' do
        let(:time_estimate) { '1d' }

        it 'returns true' do
          expect(subject).to eq(true)
        end
      end
    end
  end
end
