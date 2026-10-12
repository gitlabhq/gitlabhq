# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Todos::Create, feature_category: :notifications do
  include GraphqlHelpers
  include DesignManagementTestHelpers

  let(:current_user) { create(:user) }

  describe '#resolve' do
    context 'when target does not support todos' do
      it 'raises error' do
        target = create(:milestone)
        input = { target_id: global_id_of(target).to_s }
        mutation = graphql_mutation(described_class, input)
        headers = { "Referer" => "foobar", "User-Agent" => "user-agent" }
        request = instance_double(ActionDispatch::Request, headers: headers, env: nil)

        response = GitlabSchema.execute(
          mutation.query,
          context: query_context(request: request),
          variables: mutation.variables
        ).to_h

        expect(response).to include(
          'errors' => contain_exactly(
            include('message' => /invalid value for targetId/)
          )
        )
      end
    end

    context 'with issue as target' do
      it_behaves_like 'create todo mutation' do
        let_it_be(:target) { create(:issue) }
      end
    end

    context 'with merge request as target' do
      it_behaves_like 'create todo mutation' do
        let_it_be(:target) { create(:merge_request) }
      end
    end

    context 'with design as target' do
      before do
        enable_design_management
      end

      it_behaves_like 'create todo mutation' do
        let_it_be(:target) { create(:design) }
      end
    end

    context 'with a note' do
      let_it_be(:project) { create(:project, :public) }
      let_it_be(:issue) { create(:issue, project: project) }
      let_it_be(:note) { create(:note, project: project, noteable: issue) }

      let(:mutation) { described_class.new(object: nil, context: query_context, field: nil) }

      subject(:resolve) { mutation.resolve(target_id: global_id_of(issue), note_id: global_id_of(note)) }

      context 'when the todo_for_comment flag is enabled' do
        it 'creates a todo on the target referencing the note' do
          result = resolve

          expect(result[:todo]).to be_valid
          expect(result[:todo].target).to eq(issue)
          expect(result[:todo].note).to eq(note)
          expect(result[:todo].state).to eq('pending')
        end

        context 'when the target is the work item for the note' do
          it 'creates the todo referencing the note' do
            result = mutation.resolve(
              target_id: global_id_of(WorkItem.find(issue.id)), note_id: global_id_of(note)
            )

            expect(result[:todo]).to be_valid
            expect(result[:todo].note).to eq(note)
          end
        end

        context 'when the user already has a pending todo for the target' do
          before do
            mutation.resolve(target_id: global_id_of(issue), note_id: global_id_of(note))
          end

          it 'returns no todo and no errors' do
            result = resolve

            expect(result[:todo]).to be_nil
            expect(result[:errors]).to be_nil
          end
        end

        context 'when the note does not exist' do
          subject(:resolve) do
            mutation.resolve(
              target_id: global_id_of(issue),
              note_id: global_id_of(id: non_existing_record_id, model_name: 'Note')
            )
          end

          it 'raises a resource not available error' do
            expect { resolve }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
          end
        end

        context 'when the note does not belong to the target' do
          let_it_be(:note) { create(:note, project: project, noteable: create(:issue, project: project)) }

          it 'raises a resource not available error' do
            expect { resolve }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
          end
        end

        context 'when the user cannot read the note' do
          let_it_be(:note) { create(:note, :confidential, project: project, noteable: issue) }

          it 'raises a resource not available error' do
            expect { resolve }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
          end
        end
      end

      context 'when the todo_for_comment flag is disabled' do
        before do
          stub_feature_flags(todo_for_comment: false)
        end

        it 'creates the todo without referencing the note' do
          result = resolve

          expect(result[:todo]).to be_valid
          expect(result[:todo].target).to eq(issue)
          expect(result[:todo].note).to be_nil
        end

        context 'when the user cannot read the note' do
          let_it_be(:note) { create(:note, :confidential, project: project, noteable: issue) }

          it 'creates the todo without the note and does not validate it' do
            result = resolve

            expect(result[:todo]).to be_valid
            expect(result[:todo].target).to eq(issue)
            expect(result[:todo].note).to be_nil
          end
        end
      end
    end
  end
end
