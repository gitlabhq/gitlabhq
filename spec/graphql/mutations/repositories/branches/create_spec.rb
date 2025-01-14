# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Repositories::Branches::Create, feature_category: :api do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:current_user) { create(:user) }

  subject(:mutation) { described_class.new(object: nil, context: query_context, field: nil) }

  describe '#resolve' do
    subject(:resolve) { mutation.resolve(project_path: project.full_path, name: branch, ref: ref) }

    let(:branch) { 'new_branch' }
    let(:ref) { 'master' }
    let(:mutated_branch) { resolve[:branch] }

    it 'raises an error if the resource is not accessible to the user' do
      expect { resolve }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
    end

    context 'when the user can create a branch' do
      before_all do
        project.add_developer(current_user)
      end

      before do
        allow_next_instance_of(::Branches::CreateService, project, current_user) do |create_service|
          allow(create_service).to receive(:execute).with(branch, ref) { service_result }
        end
      end

      context 'when service successfully creates a new branch' do
        let(:service_result) { { status: :success, branch: instance_double(Gitlab::Git::Branch, name: branch) } }

        it 'returns a new branch' do
          expect(mutated_branch.name).to eq(branch)
          expect(resolve[:errors]).to be_empty
        end
      end

      context 'when service fails to create a new branch' do
        let(:service_result) { { status: :error, message: 'Branch already exists' } }

        it { expect(mutated_branch).to be_nil }
        it { expect(resolve[:errors]).to eq(['Branch already exists']) }
      end
    end
  end
end
