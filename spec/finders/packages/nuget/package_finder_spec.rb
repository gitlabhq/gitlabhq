# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::Nuget::PackageFinder do
  let_it_be(:package1) { create(:nuget_package) }
  let_it_be(:project) { package1.project }
  let_it_be(:package2) { create(:nuget_package, name: package1.name, version: '2.0.0', project: project) }
  let_it_be(:package3) { create(:nuget_package, name: 'Another.Dummy.Package', project: project) }
  let(:package_name) { package1.name }
  let(:package_version) { nil }
  let(:limit) { 50 }

  describe '#execute!' do
    subject { described_class.new(project, package_name: package_name, package_version: package_version, limit: limit).execute }

    it { is_expected.to match_array([package1, package2]) }

    context 'with lower case package name' do
      let(:package_name) { package1.name.downcase }

      it { is_expected.to match_array([package1, package2]) }
    end

    context 'with unknown package name' do
      let(:package_name) { 'foobar' }

      it { is_expected.to be_empty }
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
end
