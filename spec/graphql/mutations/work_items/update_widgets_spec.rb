# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::WorkItems::UpdateWidgets do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user).tap { |user| project.add_developer(user) } }

  let(:mutation) { described_class.new(object: nil, context: { current_user: current_user }, field: nil) }

  describe '#resolve' do
    before do
      stub_spam_services
    end

    context 'when no work item matches the given id' do
      let(:current_user) { developer }
      let(:gid) { global_id_of(id: non_existing_record_id, model_name: WorkItem.name) }

      it 'raises an error' do
        expect { mutation.resolve(id: gid, resolve: true) }.to raise_error(
          Gitlab::Graphql::Errors::ResourceNotAvailable,
          Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR
        )
      end
    end

    context 'when user can access the requested work item', :aggregate_failures do
      let(:current_user) { developer }
      let(:args) { {} }

      let_it_be(:work_item) { create(:work_item, project: project) }

      subject { mutation.resolve(id: work_item.to_global_id, **args) }

      context 'when `:work_items` is disabled for a project' do
        let_it_be(:project2) { create(:project) }

        it 'returns an error' do
          stub_feature_flags(work_items: project2) # only enable `work_item` for project2

          expect(subject[:errors]).to contain_exactly('`work_items` feature flag disabled for this project')
        end
      end

      context 'when resolved with an input for description widget' do
        let(:args) { { description_widget: { description: "updated description" } } }

        it 'returns the updated work item' do
          expect(subject[:work_item].description).to eq("updated description")
          expect(subject[:errors]).to be_empty
        end
      end
    end
  end
end
