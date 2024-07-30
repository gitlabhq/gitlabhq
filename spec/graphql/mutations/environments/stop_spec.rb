# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Environments::Stop, feature_category: :environment_management do
  include GraphqlHelpers
  let_it_be(:project) { create(:project) }
  let_it_be(:environment) { create(:environment, project: project, state: 'available') }
  let_it_be(:maintainer) { create(:user, maintainer_of: project) }
  let_it_be(:reporter) { create(:user, reporter_of: project) }

  let(:current_user) { maintainer }

  subject(:mutation) { described_class.new(object: nil, context: query_context, field: nil) }

  describe '#resolve' do
    subject { mutation.resolve(id: environment_id, force: force) }

    let(:environment_id) { environment.to_global_id }
    let(:force) { false }

    context 'when service execution succeeded' do
      it 'returns no errors' do
        expect(subject[:errors]).to be_empty
      end

      it 'stops the environment' do
        expect(subject[:environment]).to be_stopped
      end
    end

    context 'when service cannot change the status without force' do
      before do
        environment.update!(state: 'stopping')
      end

      it 'returns an error' do
        expect(subject)
          .to eq({
            environment: environment,
            errors: ['Attempted to stop the environment but failed to change the status']
          })
      end
    end

    context 'when force is set to true' do
      let(:force) { true }

      context 'and state transition would fail without force' do
        before do
          environment.update!(state: 'stopping')
        end

        it 'stops the environment' do
          expect(subject[:environment]).to be_stopped
        end
      end
    end

    context 'when user is reporter who does not have permission to access the environment' do
      let(:current_user) { reporter }

      it 'raises an error' do
        expect { subject }.to raise_error(Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR)
      end
    end
  end
end
