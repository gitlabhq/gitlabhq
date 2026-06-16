# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Packages::Cargo::PackageFinder, feature_category: :package_registry do
  let_it_be(:project, freeze: false) { create(:project) }
  let_it_be(:package, freeze: false) { create(:cargo_package, name: 'my-crate', version: '1.0.0', project: project) }
  let_it_be(:metadatum, freeze: false) { create(:cargo_metadatum, package: package) }

  let(:package_name) { package.name }
  let(:package_version) { package.version }

  subject(:execute) do
    described_class.new(project, package_name: package_name, package_version: package_version).execute
  end

  describe '#execute' do
    it 'returns the matching package' do
      expect(execute).to contain_exactly(package)
    end

    context 'when the name uses uppercase letters' do
      let(:package_name) { 'My-Crate' }

      it 'matches via the normalized name' do
        expect(execute).to contain_exactly(package)
      end
    end

    context 'when the name uses underscores instead of hyphens' do
      let_it_be(:underscore_package, freeze: false) do
        create(:cargo_package, name: 'with-underscore', version: '2.0.0', project: project)
      end

      let_it_be(:underscore_metadatum, freeze: false) { create(:cargo_metadatum, package: underscore_package) }

      let(:package_name) { 'with_underscore' }
      let(:package_version) { '2.0.0' }

      it 'matches via the normalized name' do
        expect(execute).to contain_exactly(underscore_package)
      end
    end

    context 'when the version includes a build metadata suffix' do
      let_it_be(:plain_version_package, freeze: false) do
        create(:cargo_package, name: 'plain-version', version: '3.0.0', project: project)
      end

      let_it_be(:plain_version_metadatum, freeze: false) { create(:cargo_metadatum, package: plain_version_package) }

      let(:package_name) { 'plain-version' }
      let(:package_version) { '3.0.0+build42' }

      it 'matches via the normalized version' do
        expect(execute).to contain_exactly(plain_version_package)
      end
    end

    context 'when no package matches the name' do
      let(:package_name) { 'does-not-exist' }

      it { is_expected.to be_empty }
    end

    context 'when no package matches the version' do
      let(:package_version) { '9.9.9' }

      it { is_expected.to be_empty }
    end

    context 'when the package_name is blank' do
      let(:package_name) { '' }

      it { is_expected.to be_empty }
    end

    context 'when the package_version is blank' do
      let(:package_version) { nil }

      it { is_expected.to be_empty }
    end

    context 'when the project is nil' do
      subject(:execute) do
        described_class.new(nil, package_name: package_name, package_version: package_version).execute
      end

      it { is_expected.to be_empty }
    end

    context 'when the package belongs to a different project' do
      let_it_be(:other_project, freeze: false) { create(:project) }

      subject(:execute) do
        described_class.new(
          other_project,
          package_name: package_name,
          package_version: package_version
        ).execute
      end

      it { is_expected.to be_empty }
    end

    context 'when the package is not in an installable status' do
      before do
        package.update_column(:status, :error)
      end

      it { is_expected.to be_empty }
    end
  end
end
