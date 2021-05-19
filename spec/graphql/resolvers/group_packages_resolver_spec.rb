# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::GroupPackagesResolver do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :public, group: group) }

  let(:args) do
    { sort: :created_desc }
  end

  describe '#resolve' do
    subject { resolve(described_class, ctx: { current_user: user }, obj: group, args: args).to_a }

    it_behaves_like 'group and projects packages resolver'
  end
end
