# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Environments::Delete, feature_category: :environment_management do
  include GraphqlHelpers
  let_it_be(:project) { create(:project) }
  let_it_be(:maintainer) { create(:user, maintainer_of: project) }
  let_it_be(:reporter) { create(:user, reporter_of: project) }

  let(:environment) { create(:environment, project: project, state: state) }
  let(:current_user) { maintainer }

  subject(:mutation) { described_class.new(object: nil, context: query_context, field: nil) }

  describe '#resolve' do
    subject { mutation.resolve(id: environment_id) }

    let(:environment_id) { environment.to_global_id }

    context 'when destroying the environment succeeds' do
      let(:state) { 'stopped' }

      it 'returns no errors' do
        expect(subject[:errors]).to be_empty
      end

      it 'deletes the environment' do
        expect { subject }
          .to change { project.reload.environments.include?(environment) }
          .from(true)
          .to(false)
      end
    end

    context 'when the mutation is not authorized' do
      let(:state) { 'available' } # stopped state is a necessary condition in EnvironmentPolicy

      it 'returns errors' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when destroying the environment fails' do
      let(:state) { 'stopped' }

      before do
        allow_next_found_instance_of(Environment) do |environment|
          allow(environment).to receive(:destroy)
          .and_return(false)
        end
      end

      it 'returns errors' do
        expect(subject[:errors]).to include("Attempted to destroy the environment but failed")
      end
    end

    context 'when user is reporter who does not have permission to access the environment' do
      let(:current_user) { reporter }
      let(:state) { 'stopped' }

      it 'raises an error' do
        expect { subject }.to raise_error(Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR)
      end
    end
  end
end
