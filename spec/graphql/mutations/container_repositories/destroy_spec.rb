# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::ContainerRepositories::Destroy, feature_category: :container_registry do
  include GraphqlHelpers
  using RSpec::Parameterized::TableSyntax

  let_it_be_with_reload(:container_repository) { create(:container_repository) }
  let_it_be(:current_user) { create(:user) }

  let(:project) { container_repository.project }
  let(:id) { container_repository.to_global_id }

  specify { expect(described_class).to require_graphql_authorizations(:destroy_container_image) }

  describe '#resolve' do
    subject do
      described_class.new(object: nil, context: query_context, field: nil)
                     .resolve(id: id)
    end

    shared_examples 'destroying the container repository' do
      it 'marks the repository as delete_scheduled' do
        expect(::Packages::CreateEventService)
          .to receive(:new).with(nil, current_user, event_name: :delete_repository, scope: :container).and_call_original

        subject
        expect(container_repository.reload.delete_scheduled?).to be true
      end
    end

    shared_examples 'denying access to container respository' do
      it 'raises an error' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'with valid id' do
      where(:user_role, :shared_examples_name) do
        :maintainer | 'destroying the container repository'
        :developer  | 'destroying the container repository'
        :reporter   | 'denying access to container respository'
        :guest      | 'denying access to container respository'
        :anonymous  | 'denying access to container respository'
      end

      with_them do
        before do
          project.send("add_#{user_role}", current_user) unless user_role == :anonymous
        end

        it_behaves_like params[:shared_examples_name]
      end
    end
  end
end
