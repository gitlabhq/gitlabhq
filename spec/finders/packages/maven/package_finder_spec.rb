# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Packages::Maven::PackageFinder do
  let_it_be(:user)    { create(:user) }
  let_it_be(:group)   { create(:group) }
  let_it_be(:project) { create(:project, namespace: group) }
  let_it_be_with_refind(:package) { create(:maven_package, project: project) }

  let(:param_path) { nil }
  let(:project_or_group) { nil }
  let(:param_order_by_package_file) { false }
  let(:finder) { described_class.new(user, project_or_group, path: param_path, order_by_package_file: param_order_by_package_file) }

  before do
    group.add_developer(user)
  end

  describe '#execute!' do
    subject { finder.execute! }

    shared_examples 'handling valid and invalid paths' do
      context 'with a valid path' do
        let(:param_path) { package.maven_metadatum.path }

        it { is_expected.to eq(package) }
      end

      context 'with an invalid path' do
        let(:param_path) { 'com/example/my-app/1.0-SNAPSHOT' }

        it 'raises an error' do
          expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context 'with an uninstallable package' do
        let(:param_path) { package.maven_metadatum.path }

        before do
          package.update_column(:status, 1)
        end

        it { expect { subject }.to raise_error(ActiveRecord::RecordNotFound) }
      end
    end

    context 'within the project' do
      let(:project_or_group) { project }

      it_behaves_like 'handling valid and invalid paths'
    end

    context 'within a group' do
      let(:project_or_group) { group }

      it_behaves_like 'handling valid and invalid paths'
    end

    context 'across all projects' do
      it 'raises an error' do
        expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'versionless maven-metadata.xml package' do
      let_it_be(:sub_group1) { create(:group, parent: group) }
      let_it_be(:sub_group2)   { create(:group, parent: group) }
      let_it_be(:project1) { create(:project, group: sub_group1) }
      let_it_be(:project2) { create(:project, group: sub_group2) }
      let_it_be(:project3) { create(:project, group: sub_group1) }
      let_it_be(:package_name) { 'foo' }
      let_it_be(:package1) { create(:maven_package, project: project1, name: package_name, version: nil) }
      let_it_be(:package2) { create(:maven_package, project: project2, name: package_name, version: nil) }
      let_it_be(:package3) { create(:maven_package, project: project3, name: package_name, version: nil) }

      let(:project_or_group) { group }
      let(:param_path) { package_name }

      before do
        sub_group1.add_developer(user)
        sub_group2.add_developer(user)
        # the package with the most recently published file should be returned
        create(:package_file, :xml, package: package2)
      end

      context 'without order by package file' do
        it { is_expected.to eq(package3) }
      end

      context 'with order by package file' do
        let(:param_order_by_package_file) { true }

        it { is_expected.to eq(package2) }
      end
    end
  end

  it 'uses CTE in the query' do
    sql = described_class.new(user, group, path: package.maven_metadatum.path).send(:packages).to_sql

    expect(sql).to include('WITH "maven_metadata_by_path" AS')
  end
end
