# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Pages::MarkOnboardingComplete do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:owner) { create(:user, owner_of: project) }

  let(:mutation) { described_class.new(object: nil, context: query_context, field: nil) }

  let(:mutation_arguments) do
    {
      project_path: project.full_path
    }
  end

  describe '#resolve' do
    subject(:resolve) do
      mutation.resolve(**mutation_arguments)
    end

    context 'when the current user has access to update pages' do
      let(:current_user) { owner }

      it 'calls mark_pages_onboarding_complete on the project' do
        allow_next_instance_of(::Project) do |project|
          expect(project).to receive(:mark_pages_onboarding_complete)
        end
      end

      it 'returns onboarding_complete state' do
        expect(resolve).to include(onboarding_complete: true)
      end

      it 'returns no errors' do
        expect(resolve).to include(errors: [])
      end
    end

    context "when the current user doesn't have access to update pages" do
      let(:current_user) { developer }

      it 'raises an error' do
        expect { subject }.to raise_error(
          Gitlab::Graphql::Errors::ResourceNotAvailable,
          Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR
        )
      end
    end
  end
end
