# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::ReleaseAssetLinks::Delete do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :private, :repository) }
  let_it_be_with_reload(:release) { create(:release, project: project) }
  let_it_be(:developer) { create(:user).tap { |u| project.add_developer(u) } }
  let_it_be(:maintainer) { create(:user).tap { |u| project.add_maintainer(u) } }
  let_it_be_with_reload(:release_link) { create(:release_link, release: release) }

  let(:mutation) { described_class.new(object: nil, context: { current_user: current_user }, field: nil) }
  let(:mutation_arguments) { { id: release_link.to_global_id } }

  describe '#resolve' do
    subject(:resolve) do
      mutation.resolve(**mutation_arguments)
    end

    let(:deleted_link) { subject[:link] }

    context 'when the current user has access to delete the link' do
      let(:current_user) { maintainer }

      it 'deletes the link and returns it', :aggregate_failures do
        expect(deleted_link).to eq(release_link)

        expect(release.links).to be_empty
      end

      context "when the link doesn't exist" do
        let(:mutation_arguments) { super().merge(id: "gid://gitlab/Releases::Link/#{non_existing_record_id}") }

        it 'raises an error' do
          expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        end
      end

      context "when the provided ID is invalid" do
        let(:mutation_arguments) { super().merge(id: 'not-a-valid-gid') }

        it 'raises an error' do
          expect { subject }.to raise_error(::GraphQL::CoercionError)
        end
      end
    end

    context 'when the current user does not have access to delete the link' do
      let(:current_user) { developer }

      it 'raises an error' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end
  end
end
