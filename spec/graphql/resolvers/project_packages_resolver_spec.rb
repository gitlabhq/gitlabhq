# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::ProjectPackagesResolver do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:project) { create(:project, :public) }

  let(:args) do
    { sort: :created_desc }
  end

  describe '#resolve' do
    subject { resolve(described_class, ctx: { current_user: user }, obj: project, args: args).to_a }

    it_behaves_like 'group and projects packages resolver'
  end
end
