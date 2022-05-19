# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::DesignManagement::VersionInCollectionResolver do
  include GraphqlHelpers
  include DesignManagementTestHelpers

  let(:resolver) { described_class }

  describe '#resolve' do
    let_it_be(:issue) { create(:issue) }
    let_it_be(:current_user) { create(:user) }
    let_it_be(:first_version) { create(:design_version, issue: issue) }

    let(:project) { issue.project }
    let(:params) { {} }

    before do
      enable_design_management
      project.add_developer(current_user)
    end

    let(:appropriate_error) { ::Gitlab::Graphql::Errors::ArgumentError }

    subject(:result) { resolve_version(issue.design_collection) }

    context 'Neither id nor sha is passed as parameters' do
      it 'generates an appropriate error' do
        expect_graphql_error_to_be_created(appropriate_error) do
          result
        end
      end
    end

    context 'we pass an id' do
      let(:params) { { id: global_id_of(first_version) } }

      it { is_expected.to eq(first_version) }
    end

    context 'we pass a sha' do
      let(:params) { { sha: first_version.sha } }

      it { is_expected.to eq(first_version) }
    end

    context 'we pass an inconsistent mixture of sha and version id' do
      let(:params) { { sha: first_version.sha, id: global_id_of(create(:design_version)) } }

      it { is_expected.to be_nil }
    end
  end

  def resolve_version(obj, context = { current_user: current_user })
    resolve(resolver, obj: obj, args: params, ctx: context)
  end
end
