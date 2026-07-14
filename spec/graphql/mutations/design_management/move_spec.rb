# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::DesignManagement::Move, feature_category: :api do
  include DesignManagementTestHelpers
  include GraphqlHelpers

  let_it_be(:issue) { create(:issue) }
  let_it_be(:designs) { create_list(:design, 3, issue: issue) }
  let_it_be(:developer) { create(:user, developer_of: issue.project) }

  let(:current_user) { developer }

  let(:mutation) { described_class.new(object: nil, context: query_context, field: nil) }

  let(:current_design) { designs.first }
  let(:previous_design) { designs.second }
  let(:next_design) { designs.third }

  before do
    enable_design_management
  end

  describe "#resolve" do
    subject(:resolve) do
      args = {
        current_design: current_design.to_global_id,
        previous_design: previous_design&.to_global_id,
        next_design: next_design&.to_global_id
      }.compact

      mutation.resolve(**args)
    end

    shared_examples "resource not available" do
      it "raises an error" do
        expect { resolve }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when the feature is not available' do
      before do
        enable_design_management(false)
      end

      it_behaves_like 'resource not available'
    end

    %i[current_design previous_design next_design].each do |binding|
      context "When #{binding} cannot be found" do
        let(binding) { build_stubbed(:design) }

        it_behaves_like 'resource not available'
      end
    end

    context 'the service runs' do
      before do
        expect_next_instance_of(::DesignManagement::MoveDesignsService) do |service|
          expect(service).to receive(:execute).and_return(service_result)
        end
      end

      context 'raising an error' do
        let(:service_result) { ServiceResponse.error(message: 'bang!') }

        it 'reports the service-level error' do
          expect(resolve).to include(errors: ['bang!'], design_collection: eq(issue.design_collection))
        end
      end

      context 'successfully' do
        let(:service_result) { ServiceResponse.success }

        it 'reports the service-level error' do
          expect(resolve).to include(errors: be_empty, design_collection: eq(issue.design_collection))
        end
      end
    end
  end
end
