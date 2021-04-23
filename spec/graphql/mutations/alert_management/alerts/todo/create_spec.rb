# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::AlertManagement::Alerts::Todo::Create do
  subject(:mutation) { described_class.new(object: project, context: { current_user: current_user }, field: nil) }

  let_it_be(:alert) { create(:alert_management_alert) }
  let_it_be(:project) { alert.project }

  let(:current_user) { project.owner }

  let(:args) { { project_path: project.full_path, iid: alert.iid } }

  specify { expect(described_class).to require_graphql_authorizations(:update_alert_management_alert) }

  describe '#resolve' do
    subject(:resolve) { mutation.resolve(args) }

    it_behaves_like 'an incident management tracked event', :incident_management_alert_todo

    context 'when user does not have permissions' do
      let(:current_user) { nil }

      specify { expect { resolve }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable) }
    end

    context 'when project is invalid' do
      let(:args) { { project_path: 'bunk/path', iid: alert.iid } }

      specify { expect { resolve }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable) }
    end

    context 'when alert is invalid' do
      let(:args) { { project_path: project.full_path, iid: "-1" } }

      specify { expect { resolve }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable) }
    end

    context 'when the create service yields errors' do
      let(:error_response) { double(error?: true, message: 'error', payload: { alert: {} }) }

      before do
        allow_next_instance_of(::AlertManagement::Alerts::Todo::CreateService) do |service|
          allow(service).to receive(:execute).and_return(error_response)
        end
      end

      specify { expect { resolve }.not_to change(Todo, :count) }
      specify { expect(resolve[:errors]).to eq([error_response.message]) }
    end

    context 'with valid inputs' do
      it 'creates a new todo' do
        expect { resolve }.to change { Todo.where(user: current_user, action: Todo::MARKED).count }.by(1)
      end

      it { is_expected.to eq(alert: alert, todo: Todo.last, errors: []) }
    end
  end
end
