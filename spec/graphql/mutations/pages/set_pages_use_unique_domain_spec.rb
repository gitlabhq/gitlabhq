# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Pages::SetPagesUseUniqueDomain, feature_category: :pages do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :public) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:owner) { create(:user, owner_of: project) }

  let(:mutation) { described_class.new(object: nil, context: query_context, field: nil) }
  let(:mutation_arguments) do
    {
      project_path: project.full_path,
      value: true
    }
  end

  describe '#resolve' do
    subject(:resolve) { mutation.resolve(**mutation_arguments) }

    context 'when the current user has owner access to the project' do
      let_it_be(:current_user) { owner }

      it 'enables pages unique domain for the project' do
        stub_pages_setting(enabled: true)
        project.project_setting.update!(pages_unique_domain_enabled: false, pages_unique_domain: 'test-domain')

        result = resolve

        expect(result[:project].reload.project_setting.pages_unique_domain_enabled?).to be true
      end

      context 'when setting unique domain to false' do
        let(:mutation_arguments) do
          {
            project_path: project.full_path,
            value: false
          }
        end

        it 'disables pages unique domain for the project' do
          stub_pages_setting(enabled: true)
          project.project_setting.update!(pages_unique_domain_enabled: true, pages_unique_domain: 'test-domain')

          result = resolve

          expect(result[:project].reload.project_setting.pages_unique_domain_enabled?).to be false
        end
      end

      context 'when validation fails due to missing unique domain' do
        before do
          stub_pages_setting(enabled: true)
          # Clear any existing unique domain to trigger presence validation
          project.project_setting.update_columns(pages_unique_domain: nil, pages_unique_domain_enabled: false)
        end

        it 'returns validation errors for the project' do
          result = resolve

          expect(result[:project]).to be_nil
          expect(result[:errors]).to include("Pages unique domain can't be blank")
        end
      end
    end

    context 'when the current user does not have sufficient permissions' do
      let_it_be(:current_user) { developer }

      it 'raises an authorization error' do
        expect { resolve }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when the project does not exist' do
      let(:mutation_arguments) do
        {
          project_path: 'non-existent/project',
          value: true
        }
      end

      let_it_be(:current_user) { owner }

      it 'raises a not found error' do
        expect { resolve }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end
  end
end
