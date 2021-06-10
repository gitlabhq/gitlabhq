# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::GroupPackagesResolver do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :public, group: group, path: 'a') }

  let(:args) do
    { sort: :created_desc }
  end

  describe '#resolve' do
    subject { resolve(described_class, ctx: { current_user: user }, obj: group, args: args).to_a }

    it_behaves_like 'group and projects packages resolver'

    describe 'project_path sorting' do
      let_it_be(:project2) { create(:project, :public, group: group, path: 'b') }
      let_it_be(:package) { create(:package, project: project ) }
      let_it_be(:package2) { create(:package, project: project2 ) }
      let_it_be(:package3) { create(:package, project: project ) }
      let_it_be(:package4) { create(:package, project: project2 ) }

      context 'filter by package_name' do
        let(:args) { { sort: :project_path_desc } }

        it { is_expected.to eq([package4, package2, package3, package]) }
      end

      context 'filter by package_type' do
        let(:args) { { sort: :project_path_asc } }

        it { is_expected.to eq([package, package3, package2, package4]) }
      end
    end
  end
end
