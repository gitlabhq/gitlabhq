# frozen_string_literal: true
require 'spec_helper'

RSpec.describe ::Packages::Npm::PackageFinder do
  let_it_be_with_reload(:project) { create(:project)}
  let_it_be_with_refind(:package) { create(:npm_package, project: project) }

  let(:project) { package.project }
  let(:package_name) { package.name }

  shared_examples 'accepting a namespace for' do |example_name|
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
      end
    end

    context 'that is a user namespace' do
      let_it_be(:user) { create(:user) }
      let_it_be(:namespace) { user.namespace }

      it_behaves_like example_name
    end
  end

  describe '#execute' do
    shared_examples 'finding packages by name' do
      it { is_expected.to eq([package]) }

      context 'with unknown package name' do
        let(:package_name) { 'baz' }

        it { is_expected.to be_empty }
      end

      context 'with an uninstallable package' do
        before do
          package.update_column(:status, 1)
        end

        it { is_expected.to be_empty }
      end
    end

    subject { finder.execute }

    context 'with a project' do
      let(:finder) { described_class.new(package_name, project: project) }

      it_behaves_like 'finding packages by name'

      context 'set to nil' do
        let(:project) { nil }

        it { is_expected.to be_empty }
      end
    end

    context 'with a namespace' do
      let(:finder) { described_class.new(package_name, namespace: namespace) }

      it_behaves_like 'accepting a namespace for', 'finding packages by name'

      context 'set to nil' do
        let_it_be(:namespace) { nil }

        it { is_expected.to be_empty }
      end
    end
  end

  describe '#find_by_version' do
    let(:version) { package.version }

    subject { finder.find_by_version(version) }

    shared_examples 'finding packages by version' do
      it { is_expected.to eq(package) }

      context 'with unknown version' do
        let(:version) { 'foobar' }

        it { is_expected.to be_nil }
      end
    end

    context 'with a project' do
      let(:finder) { described_class.new(package_name, project: project) }

      it_behaves_like 'finding packages by version'
    end

    context 'with a namespace' do
      let(:finder) { described_class.new(package_name, namespace: namespace) }

      it_behaves_like 'accepting a namespace for', 'finding packages by version'
    end
  end

  describe '#last' do
    subject { finder.last }

    shared_examples 'finding package by last' do
      it { is_expected.to eq(package) }
    end

    context 'with a project' do
      let(:finder) { described_class.new(package_name, project: project) }

      it_behaves_like 'finding package by last'
    end

    context 'with a namespace' do
      let(:finder) { described_class.new(package_name, namespace: namespace) }

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
