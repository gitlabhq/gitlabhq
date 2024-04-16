# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::WorkItemResolver do
  include GraphqlHelpers

  describe '#resolve' do
    let_it_be(:developer) { create(:user) }
    let_it_be(:project) { create(:project, :private, developers: developer) }
    let_it_be(:work_item) { create(:work_item, project: project) }

    let(:current_user) { developer }

    subject(:resolved_work_item) { resolve_work_item('id' => work_item.to_gid) }

    context 'when the user can read the work item' do
      it { is_expected.to eq(work_item) }
    end

    context 'when the user can not read the work item' do
      let(:current_user) { create(:user) }

      it 'raises a resource not available error' do
        expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ResourceNotAvailable) do
          resolved_work_item
        end
      end
    end
  end

  private

  def resolve_work_item(args = {})
    resolve(described_class, args: args, ctx: { current_user: current_user })
  end
end
