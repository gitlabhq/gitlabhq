# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Packages::Maven::GroupsAndProjectsPackageFilesFinder, :aggregate_failures, feature_category: :package_registry do
  using RSpec::Parameterized::TableSyntax

  describe '#execute' do
    let_it_be(:package_name) { 'my/company/app/my-app' }
    let_it_be(:package_version) { '1.2.3' }
    let_it_be(:filename) { 'maven-metadata.xml' }
    let_it_be(:top_level_group) { create(:group) }
    let_it_be(:subgroup) { create(:group, parent: top_level_group) }
    let_it_be(:top_level_project) { create(:project, namespace: top_level_group) }
    let_it_be(:subproject) { create(:project, namespace: subgroup) }
    let_it_be(:top_level_package_file) do
      create(:maven_package, name: package_name, version: package_version, project: top_level_project)
        .package_files.find { |pf| pf.file_name == filename }
    end

    let_it_be(:subproject_package_file) do
      create(:maven_package, name: package_name, version: package_version, project: subproject)
        .package_files.find { |pf| pf.file_name == filename }
    end

    let(:finder) { described_class.new(path:, group_ids:, project_ids:) }

    subject(:execute) { finder.execute }

    # rubocop: disable Layout/LineLength -- table based specs
    where(:groups, :projects, :expected_package_files) do
      # project ids only
      [] | [ref(:top_level_project)]                   | [ref(:top_level_package_file)]
      [] | [ref(:subproject)]                          | [ref(:subproject_package_file)]
      [] | [ref(:top_level_project), ref(:subproject)] | [ref(:top_level_package_file), ref(:subproject_package_file)]

      # group ids only
      [ref(:top_level_group)]                 | [] | [ref(:top_level_package_file), ref(:subproject_package_file)]
      [ref(:subgroup)]                        | [] | [ref(:subproject_package_file)]
      [ref(:top_level_group), ref(:subgroup)] | [] | [ref(:top_level_package_file), ref(:subproject_package_file)]

      # mixed ids
      [ref(:top_level_group)] | [ref(:top_level_project)]                   | [ref(:top_level_package_file), ref(:subproject_package_file)]
      [ref(:top_level_group)] | [ref(:top_level_project), ref(:subproject)] | [ref(:top_level_package_file), ref(:subproject_package_file)]
      [ref(:top_level_group)] | [ref(:subproject)]                          | [ref(:top_level_package_file), ref(:subproject_package_file)]

      [ref(:subgroup)] | [ref(:top_level_project)]                   | [ref(:top_level_package_file), ref(:subproject_package_file)]
      [ref(:subgroup)] | [ref(:top_level_project), ref(:subproject)] | [ref(:top_level_package_file), ref(:subproject_package_file)]
      [ref(:subgroup)] | [ref(:subproject)]                          | [ref(:subproject_package_file)]

      [ref(:top_level_group), ref(:subgroup)] | [ref(:top_level_project)]                   | [ref(:top_level_package_file), ref(:subproject_package_file)]
      [ref(:top_level_group), ref(:subgroup)] | [ref(:top_level_project), ref(:subproject)] | [ref(:top_level_package_file), ref(:subproject_package_file)]
      [ref(:top_level_group), ref(:subgroup)] | [ref(:subproject)]                          | [ref(:top_level_package_file), ref(:subproject_package_file)]
    end
    # rubocop: enable Layout/LineLength

    with_them do
      let(:group_ids) { groups.map(&:id) }
      let(:project_ids) { projects.map(&:id) }
      let(:path) { "#{package_name}/#{package_version}/#{filename}" }

      it { is_expected.to match_array(expected_package_files) }
    end

    context 'with duplicates' do
      let_it_be(:extra_subproject_package_file1) do
        create(:package_file, :xml, package_id: subproject_package_file.package_id)
      end

      let_it_be(:extra_subproject_package_file2) do
        create(:package_file, :xml, package_id: subproject_package_file.package_id)
      end

      let_it_be(:extra_subproject_package_file3) do
        create(:package_file, :xml, package_id: subproject_package_file.package_id)
      end

      let(:group_ids) { [] }
      let(:project_ids) { [top_level_project, subproject].map(&:id) }
      let(:path) { "#{package_name}/#{package_version}/#{filename}" }

      it { is_expected.to contain_exactly(top_level_package_file, extra_subproject_package_file3) }
    end

    context 'with empty group_ids and empty project_ids' do
      let(:group_ids) { [] }
      let(:project_ids) { [] }
      let(:path) { 'test' }

      it { is_expected.to be_empty }
    end

    context 'with too many group_ids and project_ids' do
      let(:group_ids) { (1..15).to_a }
      let(:project_ids) { (1..15).to_a }
      let(:path) { 'test' }

      it { is_expected.to be_empty }
    end

    context 'with invalid path' do
      let(:group_ids) { (1..5).to_a }
      let(:project_ids) { (1..5).to_a }
      let(:path) { 'single_folder' }

      it { is_expected.to be_empty }
    end
  end
end
