# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Pages::SetPagesForceHttps, feature_category: :pages do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :public) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:owner) { create(:user, owner_of: project) }

  let(:mutation) { described_class.new(object: nil, context: query_context, field: nil) }
  let(:value) { true }

  let(:mutation_arguments) do
    {
      project_path: project.full_path,
      value: value
    }
  end

  describe '#resolve' do
    subject(:resolve) { mutation.resolve(**mutation_arguments) }

    context 'when the current user has owner access to the project' do
      let_it_be(:current_user) { owner }

      it 'calls set_pages_force_https on the project' do
        allow_next_instance_of(::Project) do |project|
          expect(project).to receive(:set_pages_force_https).with(true)
        end
        resolve
      end

      it 'returns the project' do
        expect(resolve[:project]).to eq(project)
      end

      it 'returns no errors' do
        expect(resolve[:errors]).to be_empty
      end

      context 'when setting force https to false' do
        let(:value) { false }

        it 'calls set_pages_force_https with false' do
          allow_next_instance_of(::Project) do |project|
            expect(project).to receive(:set_pages_force_https).with(false)
          end

          resolve
        end
      end
    end

    context 'when the current user does not have owner access' do
      let_it_be(:current_user) { developer }

      it 'raises an error' do
        expect { resolve }.to raise_error(
          Gitlab::Graphql::Errors::ResourceNotAvailable,
          Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR
        )
      end
    end

    context 'when the project does not exist' do
      let_it_be(:current_user) { owner }
      let_it_be(:project) { create(:project) }

      it 'raises an error' do
        expect { resolve }.to raise_error(
          Gitlab::Graphql::Errors::ResourceNotAvailable
        )
      end
    end

    context 'when the project update fails' do
      let_it_be(:current_user) { owner }
      let_it_be(:pages_domain) do
        create(:pages_domain, :without_key, :without_certificate, domain: 'www.domain.test', project: project)
      end

      before do
        stub_config(pages: {
          external_https: true,
          custom_domain_mode: 'https',
          host: "new.domain.com"
        })
        project.update_column(:pages_https_only, false)
      end

      it 'returns errors when update fails' do
        expect(resolve[:project]).to be_nil
        expect(resolve[:errors]).to include(
          "Pages https only cannot be enabled unless all domains have TLS certificates"
        )
      end
    end
  end
end
