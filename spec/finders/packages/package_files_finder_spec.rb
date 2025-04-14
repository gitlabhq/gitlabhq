# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Packages::PackageFilesFinder, feature_category: :package_registry do
  let_it_be_with_reload(:package) { create(:maven_package) }

  let(:package_files) { package.package_files }
  let(:package_file) { package_files.first }
  let(:package_file_name) { package_file.file_name }
  let(:params) { {} }

  describe '#execute' do
    subject(:found_files) { described_class.new(package, params).execute }

    it { is_expected.to eq(package_files) }

    context 'with file_name_like' do
      let(:package_file_name) { package_file.file_name.upcase }
      let(:params) { { file_name: package_file_name, with_file_name_like: true } }

      it { is_expected.to eq([package_file]) }
    end

    context 'when there are pending_destruction package files' do
      let(:package_file_pending_destruction) do
        create(:package_file, :pending_destruction, package: package, file_name: package_file.file_name)
      end

      it { is_expected.to eq(package_files) }
      it { is_expected.not_to include(package_file_pending_destruction) }
    end

    context 'with unknown file_name' do
      let(:params) { { file_name: 'unknown.jpg' } }

      it { is_expected.to be_empty }
    end
  end
end
