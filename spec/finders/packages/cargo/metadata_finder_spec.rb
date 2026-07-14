# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Packages::Cargo::MetadataFinder, feature_category: :package_registry do
  let_it_be(:project) { create(:project) }
  let_it_be(:other_project) { create(:project) }

  let_it_be(:package_v1) { create(:cargo_package, name: 'my-crate', version: '1.0.0', project: project) }
  let_it_be(:package_v2, reload: true) { create(:cargo_package, name: 'my-crate', version: '2.0.0', project: project) }
  let_it_be(:other_name_package) { create(:cargo_package, name: 'other-crate', version: '1.0.0', project: project) }
  let_it_be(:other_project_package) do
    create(:cargo_package, name: 'my-crate', version: '1.0.0', project: other_project)
  end

  let_it_be(:metadatum_v1) { create(:cargo_metadatum, package: package_v1) }
  let_it_be(:metadatum_v2) { create(:cargo_metadatum, package: package_v2) }
  let_it_be(:other_name_metadatum) { create(:cargo_metadatum, package: other_name_package) }
  let_it_be(:other_project_metadatum) { create(:cargo_metadatum, package: other_project_package) }

  let(:package_name) { 'my-crate' }

  subject(:execute) { described_class.new(project, package_name: package_name).execute }

  describe '#execute' do
    it 'returns metadatum rows for every version of the named package, most recently published first' do
      expect(execute).to eq([metadatum_v2, metadatum_v1])
    end

    context 'when a lower version is published after a higher one' do
      let_it_be(:later_lower_package) do
        create(:cargo_package, name: 'my-crate', version: '1.5.0', project: project)
      end

      let_it_be(:later_lower_metadatum) { create(:cargo_metadatum, package: later_lower_package) }

      it 'orders by publish order, not by semantic version' do
        expect(execute).to eq([later_lower_metadatum, metadatum_v2, metadatum_v1])
      end
    end

    context 'when the requested name uses uppercase letters' do
      let(:package_name) { 'My-Crate' }

      it 'matches via the normalized name' do
        expect(execute).to eq([metadatum_v2, metadatum_v1])
      end
    end

    context 'when the requested name uses underscores instead of hyphens' do
      let_it_be(:underscore_package) do
        create(:cargo_package, name: 'with-underscore', version: '1.0.0', project: project)
      end

      let_it_be(:underscore_metadatum) { create(:cargo_metadatum, package: underscore_package) }

      let(:package_name) { 'with_underscore' }

      it 'matches via the normalized name' do
        expect(execute).to contain_exactly(underscore_metadatum)
      end
    end

    context 'when a version has a non-installable status' do
      before do
        package_v2.update_column(:status, :error)
      end

      it 'excludes that version' do
        expect(execute).to contain_exactly(metadatum_v1)
      end
    end

    context 'when no package matches the name' do
      let(:package_name) { 'does-not-exist' }

      it { is_expected.to be_empty }
    end

    context 'when the package_name is blank' do
      let(:package_name) { '' }

      it { is_expected.to be_empty }
    end

    context 'when the project is nil' do
      subject(:execute) { described_class.new(nil, package_name: package_name).execute }

      it { is_expected.to be_empty }
    end

    context 'when the package belongs to a different project' do
      subject(:execute) { described_class.new(other_project, package_name: package_name).execute }

      it 'only returns metadata for the requested project' do
        expect(execute).to contain_exactly(other_project_metadatum)
      end
    end

    context 'when the published version count exceeds MAX_VERSIONS' do
      before do
        stub_const("#{described_class}::MAX_VERSIONS", 2)
      end

      it 'caps the result set, keeping the most recently published versions' do
        metadatum_v3 = create(:cargo_metadatum,
          package: create(:cargo_package, name: 'my-crate', version: '3.0.0', project: project))

        expect(execute).to eq([metadatum_v3, metadatum_v2])
      end
    end
  end
end
