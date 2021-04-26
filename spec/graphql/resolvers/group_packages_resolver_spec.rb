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

    context 'without sort' do
      let_it_be(:package) { create(:package, project: project) }

      it { is_expected.to contain_exactly(package) }
    end

    context 'with a sort argument' do
      let_it_be(:project2) { create(:project, :public, group: group) }

      let_it_be(:sort_repository) do
        create(:conan_package, name: 'bar', project: project, created_at: 1.day.ago, version: "1.0.0")
      end

      let_it_be(:sort_repository2) do
        create(:maven_package, name: 'foo', project: project2, created_at: 1.hour.ago, version: "2.0.0")
      end

      [:created_desc, :name_desc, :version_desc, :type_asc, :project_path_desc].each do |order|
        context "#{order}" do
          let(:args) { { sort: order } }

          it { is_expected.to eq([sort_repository2, sort_repository]) }
        end
      end

      [:created_asc, :name_asc, :version_asc, :type_desc, :project_path_asc].each do |order|
        context "#{order}" do
          let(:args) { { sort: order } }

          it { is_expected.to eq([sort_repository, sort_repository2]) }
        end
      end
    end
  end
end
