# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Environments::CanaryIngress::Update do
  let_it_be(:project) { create(:project) }
  let_it_be(:environment) { create(:environment, project: project) }
  let_it_be(:maintainer) { create(:user) }
  let_it_be(:reporter) { create(:user) }

  let(:user) { maintainer }

  subject(:mutation) { described_class.new(object: nil, context: { current_user: user }, field: nil) }

  before_all do
    project.add_maintainer(maintainer)
    project.add_reporter(reporter)
  end

  describe '#resolve' do
    subject { mutation.resolve(id: environment_id, weight: weight) }

    let(:environment_id) { environment.to_global_id.to_s }
    let(:weight) { 50 }
    let(:update_service) { double('update_service') }

    before do
      allow(Environments::CanaryIngress::UpdateService).to receive(:new) { update_service }
    end

    context 'when service execution succeeded' do
      before do
        allow(update_service).to receive(:execute_async) { { status: :success } }
      end

      it 'returns no errors' do
        expect(subject[:errors]).to be_empty
      end
    end

    context 'when service encounters a problem' do
      before do
        allow(update_service).to receive(:execute_async) { { status: :error, message: 'something went wrong' } }
      end

      it 'returns an error' do
        expect(subject[:errors]).to eq(['something went wrong'])
      end
    end

    context 'when environment is not found' do
      let(:environment_id) { non_existing_record_id.to_s }

      it 'raises an error' do
        expect { subject }.to raise_error(GraphQL::CoercionError)
      end
    end

    context 'when user is reporter who does not have permission to access the environment' do
      let(:user) { reporter }

      it 'raises an error' do
        expect { subject }.to raise_error("The resource that you are attempting to access does not exist or you don't have permission to perform this action")
      end
    end
  end
end
