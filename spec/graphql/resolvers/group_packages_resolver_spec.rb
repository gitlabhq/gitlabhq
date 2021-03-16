# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::GroupPackagesResolver do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :public, group: group) }
  let_it_be(:package) { create(:package, project: project) }

  describe '#resolve' do
    subject(:packages) { resolve(described_class, ctx: { current_user: user }, obj: group) }

    it { is_expected.to contain_exactly(package) }
  end
end
