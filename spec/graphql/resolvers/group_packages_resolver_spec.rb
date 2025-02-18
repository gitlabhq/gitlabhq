# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::GroupPackagesResolver, feature_category: :package_registry do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :public, group: group, path: 'a') }

  let(:args) do
    { sort: 'CREATED_DESC' }
  end

  describe '#resolve' do
    subject { resolve(described_class, ctx: { current_user: user }, obj: group, args: args).to_a }

    it_behaves_like 'group and projects packages resolver'

    describe 'project_path sorting' do
      let_it_be(:project2) { create(:project, :public, group: group, path: 'b') }
      let_it_be(:package) { create(:generic_package, project: project) }
      let_it_be(:package2) { create(:generic_package, project: project2) }
      let_it_be(:package3) { create(:generic_package, project: project) }
      let_it_be(:package4) { create(:generic_package, project: project2) }

      context 'when sorting desc' do
        let(:args) { { sort: 'PROJECT_PATH_DESC' } }

        it { is_expected.to eq([package4, package2, package3, package]) }
      end

      context 'when sorting asc' do
        let(:args) { { sort: 'PROJECT_PATH_ASC' } }

        it { is_expected.to eq([package3, package, package4, package2]) }
      end
    end
  end
end
