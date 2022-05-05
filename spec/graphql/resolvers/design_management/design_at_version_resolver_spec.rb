# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::DesignManagement::DesignAtVersionResolver do
  include GraphqlHelpers
  include DesignManagementTestHelpers

  let_it_be(:issue) { create(:issue) }
  let_it_be(:project) { issue.project }
  let_it_be(:user) { create(:user) }
  let_it_be(:design_a) { create(:design, issue: issue) }
  let_it_be(:version_a) { create(:design_version, issue: issue, created_designs: [design_a]) }

  let(:current_user) { user }
  let(:object) { issue.design_collection }
  let(:global_id) { GitlabSchema.id_from_object(design_at_version) }

  let(:design_at_version) { ::DesignManagement::DesignAtVersion.new(design: design_a, version: version_a) }

  let(:resource_not_available) { ::Gitlab::Graphql::Errors::ResourceNotAvailable }

  before do
    enable_design_management
    project.add_developer(user)
  end

  describe '#resolve' do
    context 'when the user cannot see designs' do
      let(:current_user) { create(:user) }

      it 'generates ResourceNotAvailable' do
        expect_graphql_error_to_be_created(resource_not_available) do
          resolve_design
        end
      end
    end

    it 'returns the specified design' do
      expect(resolve_design).to eq(design_at_version)
    end

    context 'the ID belongs to a design on another issue' do
      let(:other_dav) do
        create(:design_at_version, issue: create(:issue, project: project))
      end

      let(:global_id) { global_id_of(other_dav) }

      it 'generates ResourceNotAvailable' do
        expect_graphql_error_to_be_created(resource_not_available) do
          resolve_design
        end
      end

      context 'the current object does not constrain the issue' do
        let(:object) { nil }

        it 'returns the object' do
          expect(resolve_design).to eq(other_dav)
        end
      end
    end
  end

  private

  def resolve_design
    args = { id: global_id }
    ctx = { current_user: current_user }
    eager_resolve(described_class, obj: object, args: args, ctx: ctx)
  end
end
