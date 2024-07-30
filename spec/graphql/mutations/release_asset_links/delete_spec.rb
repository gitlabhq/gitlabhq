# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::ReleaseAssetLinks::Delete, feature_category: :release_orchestration do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :private, :repository) }
  let_it_be_with_reload(:release) { create(:release, project: project) }
  let_it_be(:reporter) { create(:user, reporter_of: project) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:maintainer) { create(:user, maintainer_of: project) }
  let_it_be_with_reload(:release_link) { create(:release_link, release: release) }

  let(:mutation) { described_class.new(object: nil, context: query_context, field: nil) }
  let(:mutation_arguments) { { id: release_link.to_global_id } }

  describe '#resolve' do
    subject(:resolve) do
      mutation.resolve(**mutation_arguments)
    end

    let(:deleted_link) { subject[:link] }

    context 'when the current user has access to delete the link' do
      let(:current_user) { developer }

      it 'deletes the link and returns it', :aggregate_failures do
        expect(deleted_link).to eq(release_link)

        expect(release.links).to be_empty
      end

      context 'with protected tag' do
        context 'when user has access to the protected tag' do
          let!(:protected_tag) { create(:protected_tag, :developers_can_create, name: '*', project: project) }

          it 'does not have errors' do
            subject

            expect(resolve).to include(errors: [])
          end
        end

        context 'when user does not have access to the protected tag' do
          let!(:protected_tag) { create(:protected_tag, :maintainers_can_create, name: '*', project: project) }

          it 'raises a resource access error' do
            expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
          end
        end
      end

      context "when the link doesn't exist" do
        let(:mutation_arguments) do
          super().merge(id: global_id_of(id: non_existing_record_id, model_name: release_link.class.name))
        end

        it 'raises an error' do
          expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        end
      end

      context 'when destroy process fails' do
        before do
          allow_next_instance_of(::Releases::Links::DestroyService) do |service|
            allow(service).to receive(:execute).and_return(ServiceResponse.error(message: 'error'))
          end
        end

        it 'returns errors' do
          expect(resolve).to include(errors: 'error')
        end
      end
    end

    context 'when the current user does not have access to delete the link' do
      let(:current_user) { reporter }

      it 'raises an error' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end
  end
end
