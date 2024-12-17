# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::PackageDetailsResolver do
  include GraphqlHelpers

  let_it_be_with_reload(:project) { create(:project) }
  let_it_be(:user) { project.first_owner }
  let_it_be(:package) { create(:composer_package, project: project) }
  let(:args) { { id: global_id_of(package) } }

  subject { force(resolve(described_class, ctx: { current_user: user }, args: args)) }

  describe '#resolve' do
    context 'when package exists' do
      it { is_expected.to eq(package) }
    end

    context 'when package does not exist' do
      let(:args) { { id: global_id_of(id: non_existing_record_id, model_name: 'Packages::Package') } }

      it { is_expected.to be_nil }
    end

    context 'when package has status deprecated' do
      before do
        package.deprecated!
      end

      it { is_expected.to eq(package) }
    end
  end
end
