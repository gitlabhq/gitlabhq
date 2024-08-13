# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Discussions::ToggleResolve do
  include GraphqlHelpers

  subject(:mutation) do
    described_class.new(object: nil, context: query_context, field: nil)
  end

  let_it_be(:author) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }

  describe '#resolve' do
    subject do
      mutation.resolve(id: id_arg, resolve: resolve_arg)
    end

    let(:id_arg) { global_id_of(discussion) }
    let(:resolve_arg) { true }
    let(:mutated_discussion) { subject[:discussion] }
    let(:errors) { subject[:errors] }

    shared_examples 'a working resolve method' do
      context 'when the user does not have permission' do
        let_it_be(:current_user) { create(:user) }

        it 'raises an error if the resource is not accessible to the user' do
          expect { subject }.to raise_error(
            Gitlab::Graphql::Errors::ResourceNotAvailable,
            Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR
          )
        end
      end

      context 'when the user has permission' do
        let_it_be(:current_user) { create(:user, developer_of: project) }

        context 'when discussion cannot be found' do
          let(:id_arg) { global_id_of(id: non_existing_record_id, model_name: discussion.class.name) }

          it 'raises an error' do
            expect { subject }.to raise_error(
              Gitlab::Graphql::Errors::ResourceNotAvailable,
              Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR
            )
          end
        end

        shared_examples 'returns a resolved discussion without errors' do
          it 'returns a resolved discussion' do
            expect(mutated_discussion).to be_resolved
          end

          it 'returns empty errors' do
            expect(errors).to be_empty
          end
        end

        shared_examples 'returns an unresolved discussion without errors' do
          it 'returns an unresolved discussion' do
            expect(mutated_discussion).not_to be_resolved
          end

          it 'returns empty errors' do
            expect(errors).to be_empty
          end
        end

        context 'when the `resolve` argument is true' do
          include_examples 'returns a resolved discussion without errors'

          context 'when the discussion is already resolved' do
            before do
              discussion.resolve!(current_user)
            end

            include_examples 'returns a resolved discussion without errors'
          end

          context 'when the service raises an `ActiveRecord::RecordNotSaved` error' do
            before do
              allow_next_instance_of(::Discussions::ResolveService) do |service|
                allow(service).to receive(:execute).and_raise(ActiveRecord::RecordNotSaved)
              end
            end

            it 'does not resolve the discussion' do
              expect(mutated_discussion).not_to be_resolved
            end

            it 'returns errors' do
              expect(errors).to contain_exactly('Discussion failed to be resolved')
            end
          end
        end

        context 'when the `resolve` argument is false' do
          let(:resolve_arg) { false }

          context 'when the discussion is resolved' do
            before do
              discussion.resolve!(current_user)
            end

            include_examples 'returns an unresolved discussion without errors'

            context 'when the service raises an `ActiveRecord::RecordNotSaved` error' do
              before do
                allow_next_instance_of(discussion.class) do |instance|
                  allow(instance).to receive(:unresolve!).and_raise(ActiveRecord::RecordNotSaved)
                end
              end

              it 'does not unresolve the discussion' do
                expect(mutated_discussion).to be_resolved
              end

              it 'returns errors' do
                expect(errors).to contain_exactly('Discussion failed to be unresolved')
              end
            end
          end

          context 'when the discussion is already unresolved' do
            include_examples 'returns an unresolved discussion without errors'
          end
        end
      end

      context 'when user is the author and discussion is locked' do
        let(:current_user) { author }

        before do
          issuable.update!(discussion_locked: true)
        end

        it 'raises an error' do
          expect { mutation.resolve(id: id_arg, resolve: resolve_arg) }.to raise_error(
            Gitlab::Graphql::Errors::ResourceNotAvailable,
            "The resource that you are attempting to access does not exist or you don't have permission to perform this action"
          )
        end
      end
    end

    context 'when discussion is on a merge request' do
      let_it_be(:noteable) { create(:merge_request, source_project: project, author: author) }

      let(:discussion) { create(:diff_note_on_merge_request, noteable: noteable, project: project).to_discussion }
      let(:issuable) { noteable }

      it_behaves_like 'a working resolve method'
    end

    context 'when discussion is on a design' do
      let_it_be(:noteable) { create(:design, :with_file, issue: create(:issue, project: project, author: author)) }

      let(:discussion) { create(:diff_note_on_design, noteable: noteable, project: project).to_discussion }
      let(:issuable) { noteable.issue }

      it_behaves_like 'a working resolve method'
    end
  end
end
