# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::PackagesResolver do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:package) { create(:package, project: project) }

  describe '#resolve' do
    subject(:packages) { resolve(described_class, ctx: { current_user: user }, obj: project) }

    it { is_expected.to contain_exactly(package) }
  end
end
