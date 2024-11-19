# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Nuget::PackageFinder, feature_category: :package_registry do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:project) { create(:project, namespace: subgroup) }
  let_it_be_with_refind(:package1) { create(:nuget_package, project: project) }
  let_it_be(:package2) { create(:nuget_package, :with_metadatum, name: package1.name, version: '2.0.0+ABC', project: project) }
  let_it_be(:package3) { create(:nuget_package, name: 'Another.Dummy.Package', project: project) }
  let_it_be(:other_package_1) { create(:nuget_package, name: package1.name, version: package1.version) }
  let_it_be(:other_package_2) { create(:nuget_package, name: package1.name, version: package2.version) }

  let(:package_name) { package1.name }
  let(:package_version) { nil }
  let(:limit) { 50 }
  let(:client_version) { nil }

  describe '#execute!' do
    subject { described_class.new(user, target, package_name: package_name, package_version: package_version, limit: limit, client_version: client_version).execute }

    shared_examples 'calling with_nuget_version_or_normalized_version scope' do |with_normalized:|
      it 'calls with_nuget_version_or_normalized_version scope with the correct arguments' do
        expect(::Packages::Nuget::Package)
          .to receive(:with_nuget_version_or_normalized_version)
          .with(package_version, with_normalized: with_normalized)
          .and_call_original

        subject
      end
    end

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
          package1.update_column(:status, :error)
        end

        it { is_expected.to contain_exactly(package2) }
      end

      context 'with valid version' do
        let(:package_version) { '2.0.0+ABC' }

        it { is_expected.to match_array([package2]) }
      end

      context 'with varying case version' do
        let(:package_version) { '2.0.0+abC' }

        it { is_expected.to match_array([package2]) }
      end

      context 'with unknown version' do
        let(:package_version) { 'foobar' }

        it { is_expected.to be_empty }
      end

      context 'with normalized version' do
        let(:package_version) { '2.0.0' }

        before do
          package2.nuget_metadatum.update_column(:normalized_version, package_version)
        end

        it { is_expected.to match_array([package2]) }
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

      context 'with client version less than 3' do
        let(:package_version) { '2.0.0+abc' }
        let(:client_version) { '2.8.6' }

        it_behaves_like 'calling with_nuget_version_or_normalized_version scope', with_normalized: false
      end

      context 'with client version greater than or equal to 3' do
        let(:package_version) { '2.0.0+abc' }
        let(:client_version) { '3.5' }

        it_behaves_like 'calling with_nuget_version_or_normalized_version scope', with_normalized: true
      end

      context 'with no client version' do
        let(:package_version) { '2.0.0+abc' }

        it_behaves_like 'calling with_nuget_version_or_normalized_version scope', with_normalized: true
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

    context 'when package name is blank' do
      let(:target) { project }
      let(:package_name) { nil }

      it { is_expected.to be_empty }
    end

    context 'with public package registry in private group' do
      let(:target) { group }

      before_all do
        [subgroup, group, project].each do |entity|
          entity.reload.update!(visibility_level: Gitlab::VisibilityLevel.const_get(:PRIVATE, false))
        end
        project.project_feature.update!(package_registry_access_level: ::ProjectFeature::PUBLIC)
      end

      it { is_expected.to match_array([package1, package2]) }
    end
  end
end
