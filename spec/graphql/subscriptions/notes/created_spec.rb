# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Subscriptions::Notes::Created, feature_category: :team_planning do
  include GraphqlHelpers

  it { expect(described_class).to have_graphql_arguments(:noteable_id) }
  it { expect(described_class.payload_type).to eq(Types::Notes::NoteType) }

  describe '#resolve' do
    let_it_be(:unauthorized_user) { create(:user) }
    let_it_be(:note) { create(:note) }

    let(:current_user) { note.author }
    let(:noteable_id) { note.noteable.to_gid }

    subject(:subscription) { resolver.resolve_with_support(noteable_id: noteable_id) }

    context 'for initial subscription' do
      let(:resolver) { resolver_instance(described_class, ctx: query_context, subscription_update: false) }

      it 'returns nil' do
        expect(subscription).to be_nil
      end

      context 'when user is unauthorized' do
        let(:current_user) { unauthorized_user }

        it 'raises an exception' do
          expect { subscription }.to raise_error(GraphQL::ExecutionError)
        end
      end
    end

    context 'with subscription updates' do
      let(:resolver) do
        resolver_instance(described_class, obj: obj, ctx: query_context, subscription_update: true)
      end

      context 'when object is a Note' do
        let(:obj) { note }

        it 'returns the resolved object' do
          expect(subscription).to eq(note)
        end

        context 'when user can not read the noteable' do
          before do
            allow(Ability).to receive(:allowed?)
                    .with(current_user, :read_issue, note.noteable)
                    .and_return(false)
          end

          it 'unsubscribes the user' do
            # GraphQL::Execution::Skip is returned when unsubscribed
            expect(subscription).to be_an(GraphQL::Execution::Skip)
          end
        end

        context 'when user is unauthorized' do
          let(:current_user) { unauthorized_user }

          it 'unsubscribes the user' do
            # GraphQL::Execution::Skip is returned when unsubscribed
            expect(subscription).to be_an(GraphQL::Execution::Skip)
          end
        end
      end

      context 'when the object is a label resource event' do
        let_it_be(:project) { create(:project) }
        let_it_be(:reporter) { create(:user, reporter_of: project) }
        let_it_be(:work_item) { create(:work_item, project: project) }
        let_it_be(:label) { create(:label, project: project, title: 'foo') }
        let_it_be(:other_label) { create(:label, project: project, title: 'bar') }
        let_it_be_with_reload(:label_event) do
          create(:resource_label_event, issue: work_item, label: label, user: reporter)
        end

        let_it_be_with_reload(:other_label_event) do
          create(:resource_label_event, issue: work_item, label: other_label, user: reporter)
        end

        let(:current_user) { reporter }
        let(:noteable_id) { work_item.to_gid }

        context 'when object is a single ResourceEvent' do
          let(:obj) { label_event }

          it 'returns the synthetic system note for that event' do
            expect(subscription).to be_a(LabelNote)
            expect(subscription.noteable).to eq(work_item)
            expect(subscription.events).to contain_exactly(label_event)
          end
        end

        context 'when object is an Array of ResourceEvents' do
          let(:obj) { [label_event, other_label_event] }

          it 'returns a single synthetic system note built from all the events' do
            expect(subscription).to be_a(LabelNote)
            expect(subscription.noteable).to eq(work_item)
            expect(subscription.events).to contain_exactly(label_event, other_label_event)
          end
        end
      end
    end
  end
end
