# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::Nuget::PackageFinder do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:project) { create(:project, namespace: subgroup) }
  let_it_be_with_refind(:package1) { create(:nuget_package, project: project) }
  let_it_be(:package2) { create(:nuget_package, name: package1.name, version: '2.0.0', project: project) }
  let_it_be(:package3) { create(:nuget_package, name: 'Another.Dummy.Package', project: project) }
  let_it_be(:other_package_1) { create(:nuget_package, name: package1.name, version: package1.version) }
  let_it_be(:other_package_2) { create(:nuget_package, name: package1.name, version: package2.version) }

  let(:package_name) { package1.name }
  let(:package_version) { nil }
  let(:limit) { 50 }

  describe '#execute!' do
    subject { described_class.new(user, target, package_name: package_name, package_version: package_version, limit: limit).execute }

    shared_examples 'handling all the conditions' do
      it { is_expected.to match_array([package1, package2]) }

      context 'with lower case package name' do
        let(:package_name) { package1.name.downcase }

        it { is_expected.to match_array([package1, package2]) }
      end

      context 'with unknown package name' do
        let(:package_name) { 'foobar' }

        it { is_expected.to be_empty }
      end

      context 'with an uninstallable package' do
        before do
          package1.update_column(:status, 1)
        end

        it { is_expected.to contain_exactly(package2) }
      end

      context 'with valid version' do
        let(:package_version) { '2.0.0' }

        it { is_expected.to match_array([package2]) }
      end

      context 'with unknown version' do
        let(:package_version) { 'foobar' }

        it { is_expected.to be_empty }
      end

      context 'with limit hit' do
        let_it_be(:package4) { create(:nuget_package, name: package1.name, project: project) }
        let_it_be(:package5) { create(:nuget_package, name: package1.name, project: project) }
        let_it_be(:package6) { create(:nuget_package, name: package1.name, project: project) }

        let(:limit) { 2 }

        it { is_expected.to match_array([package5, package6]) }
      end

      context 'with downcase package name' do
        let(:package_name) { package1.name.downcase }

        it { is_expected.to match_array([package1, package2]) }
      end

      context 'with prefix wildcard' do
        let(:package_name) { "%#{package1.name[3..-1]}" }

        it { is_expected.to match_array([package1, package2]) }
      end

      context 'with suffix wildcard' do
        let(:package_name) { "#{package1.name[0..-3]}%" }

        it { is_expected.to match_array([package1, package2]) }
      end

      context 'with surrounding wildcards' do
        let(:package_name) { "%#{package1.name[3..-3]}%" }

        it { is_expected.to match_array([package1, package2]) }
      end
    end

    context 'with a project' do
      let(:target) { project }

      before do
        project.add_developer(user)
      end

      it_behaves_like 'handling all the conditions'
    end

    context 'with a subgroup' do
      let(:target) { subgroup }

      before do
        subgroup.add_developer(user)
      end

      it_behaves_like 'handling all the conditions'
    end

    context 'with a group' do
      let(:target) { group }

      before do
        group.add_developer(user)
      end

      it_behaves_like 'handling all the conditions'
    end

    context 'with nil' do
      let(:target) { nil }

      it { is_expected.to be_empty }
    end
  end
end
