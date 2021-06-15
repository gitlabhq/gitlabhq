# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::PackageDetailsResolver do
  include GraphqlHelpers

  let_it_be_with_reload(:project) { create(:project) }
  let_it_be(:user) { project.owner }
  let_it_be(:package) { create(:composer_package, project: project) }

  describe '#resolve' do
    let(:args) do
      { id: global_id_of(package) }
    end

    subject { force(resolve(described_class, ctx: { current_user: user }, args: args)) }

    it { is_expected.to eq(package) }
  end
end
