# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Packages::Npm::PackageFinder, feature_category: :package_registry do
  let_it_be_with_reload(:project) { create(:project) }
  let_it_be_with_refind(:package) { create(:npm_package, project: project) }

  let(:project) { package.project }
  let(:package_name) { package.name }
  let(:package_version) { package.version }
  let(:params) { { package_name: package_name, package_version: package_version }.compact }

  shared_examples 'accepting a namespace for' do |example_name, factory = :npm_package|
    before do
      project.update!(namespace: namespace)
    end

    context 'that is a group' do
      let_it_be(:namespace) { create(:group) }

      it_behaves_like example_name

      context 'within another group' do
        let_it_be(:subgroup) { create(:group, parent: namespace) }

        before do
          project.update!(namespace: subgroup)
        end

        it_behaves_like example_name
        it_behaves_like 'avoids N+1 database queries in the package registry', factory
      end
    end

    context 'that is a user namespace' do
      let_it_be(:user) { create(:user) }
      let_it_be(:namespace) { user.namespace }

      it_behaves_like example_name
      it_behaves_like 'avoids N+1 database queries in the package registry', factory
    end
  end

  describe '#execute' do
    subject { finder.execute }

    shared_examples 'finding packages by name' do
      let(:package_version) { nil }

      it { is_expected.to eq([package]) }

      context 'with unknown package name' do
        let(:package_name) { 'baz' }

        it { is_expected.to be_empty }
      end

      context 'with an uninstallable package' do
        before do
          package.update_column(:status, :error)
        end

        it { is_expected.to be_empty }
      end
    end

    shared_examples 'finding packages by name and version' do
      it { is_expected.to eq([package]) }

      context 'with unknown package name' do
        let(:package_name) { 'baz' }

        it { is_expected.to be_empty }
      end

      context 'with unknown package version' do
        let(:package_version) { 'foobar' }

        it { is_expected.to be_empty }
      end

      context 'with an uninstallable package' do
        before do
          package.update_column(:status, :error)
        end

        it { is_expected.to be_empty }
      end
    end

    context 'with a project' do
      let(:finder) { described_class.new(project: project, params: params) }

      it_behaves_like 'finding packages by name'
      it_behaves_like 'finding packages by name and version'
      it_behaves_like 'avoids N+1 database queries in the package registry'

      context 'set to nil' do
        let(:project) { nil }

        it { is_expected.to be_empty }
      end
    end

    context 'with a namespace' do
      let(:finder) { described_class.new(namespace: namespace, params: params) }

      it_behaves_like 'accepting a namespace for', 'finding packages by name'
      it_behaves_like 'accepting a namespace for', 'finding packages by name and version'

      context 'set to nil' do
        let_it_be(:namespace) { nil }

        it { is_expected.to be_empty }

        it_behaves_like 'avoids N+1 database queries in the package registry'
      end
    end
  end

  describe '#last' do
    let(:package_version) { nil }

    subject { finder.last }

    shared_examples 'finding package by last' do
      it { is_expected.to eq(package) }
    end

    context 'with a project' do
      let(:finder) { described_class.new(project: project, params: params) }

      it_behaves_like 'finding package by last'
    end

    context 'with a namespace' do
      let(:finder) { described_class.new(namespace: namespace, params: params) }

      it_behaves_like 'accepting a namespace for', 'finding package by last'

      context 'with duplicate packages' do
        let_it_be(:namespace) { create(:group) }
        let_it_be(:subgroup1) { create(:group, parent: namespace) }
        let_it_be(:subgroup2) { create(:group, parent: namespace) }
        let_it_be(:project2) { create(:project, namespace: subgroup2) }
        let_it_be(:package2) { create(:npm_package, name: package.name, project: project2) }

        before do
          project.update!(namespace: subgroup1)
        end

        # the most recent one is returned
        it { is_expected.to eq(package2) }
      end
    end
  end
end
