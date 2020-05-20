# frozen_string_literal: true

require 'spec_helper'

describe Resolvers::DesignManagement::VersionResolver do
  include GraphqlHelpers
  include DesignManagementTestHelpers

  let_it_be(:issue) { create(:issue) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:version) { create(:design_version, issue: issue) }
  let_it_be(:developer) { create(:user) }

  let(:project) { issue.project }
  let(:params) { { id: global_id_of(version) } }

  before do
    enable_design_management
    project.add_developer(developer)
  end

  context 'the current user is not authorized' do
    let(:current_user) { create(:user) }

    it 'raises an error on resolution' do
      expect { resolve_version }.to raise_error(::Gitlab::Graphql::Errors::ResourceNotAvailable)
    end
  end

  context 'the current user is authorized' do
    let(:current_user) { developer }

    context 'the id parameter is provided' do
      it 'returns the specified version' do
        expect(resolve_version).to eq(version)
      end
    end
  end

  def resolve_version
    resolve(described_class, obj: nil, args: params, ctx: { current_user: current_user })
  end
end
