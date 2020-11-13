# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::ContainerRepositories::Destroy do
  using RSpec::Parameterized::TableSyntax

  let_it_be_with_reload(:container_repository) { create(:container_repository) }
  let_it_be(:user) { create(:user) }

  let(:project) { container_repository.project }
  let(:id) { container_repository.to_global_id.to_s }

  specify { expect(described_class).to require_graphql_authorizations(:destroy_container_image) }

  describe '#resolve' do
    subject do
      described_class.new(object: nil, context: { current_user: user }, field: nil)
                     .resolve(id: id)
    end

    shared_examples 'destroying the container repository' do
      it 'destroys the container repistory' do
        expect(::Packages::CreateEventService)
          .to receive(:new).with(nil, user, event_name: :delete_repository, scope: :container).and_call_original
        expect(DeleteContainerRepositoryWorker)
          .to receive(:perform_async).with(user.id, container_repository.id)

        expect { subject }.to change { ::Packages::Event.count }.by(1)
        expect(container_repository.reload.delete_scheduled?).to be true
      end
    end

    shared_examples 'denying access to container respository' do
      it 'raises an error' do
        expect(DeleteContainerRepositoryWorker)
          .not_to receive(:perform_async).with(user.id, container_repository.id)

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
          project.send("add_#{user_role}", user) unless user_role == :anonymous
        end

        it_behaves_like params[:shared_examples_name]
      end
    end

    context 'with invalid id' do
      let(:id) { 'gid://gitlab/ContainerRepository/5555' }

      it_behaves_like 'denying access to container respository'
    end
  end
end
