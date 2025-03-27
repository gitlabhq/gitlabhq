# frozen_string_literal: true
require 'spec_helper'

RSpec.describe ::Packages::Conan::PackageFileFinder do
  let_it_be(:package) { create(:conan_package) }
  let_it_be(:package_file) { package.package_files.first }

  let(:package_file_name) { package_file.file_name }
  let(:params) { { file_name: package_file_name } }

  shared_examples 'package file finder examples' do
    it { is_expected.to eq(package_file) }

    context 'when there is a pending_destruction package file' do
      let_it_be(:package_file_pending_destruction) do
        create(:package_file, :pending_destruction, package: package, file_name: package_file.file_name)
      end

      it 'does not return the pending_destruction package file' do
        # Verify the pending_destruction file is indeed the last one, as only the last file is returned
        expect(package.reload.package_files.last).to eq(package_file_pending_destruction)
        expect(subject).not_to eq(package_file_pending_destruction)
      end
    end
  end

  describe '#execute' do
    subject { described_class.new(package, params).execute }

    it_behaves_like 'package file finder examples'
    context 'with unknown file_name' do
      let(:package_file_name) { 'unknown.jpg' }

      it { is_expected.to be_nil }
    end
  end

  describe '#execute!' do
    subject { described_class.new(package, params).execute! }

    it_behaves_like 'package file finder examples'

    context 'with unknown file_name' do
      let(:package_file_name) { 'unknown.jpg' }

      it { expect { subject }.to raise_error(ActiveRecord::RecordNotFound) }
    end
  end
end
