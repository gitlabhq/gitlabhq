# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::PackageFileFinder do
  let_it_be_with_reload(:package) { create(:maven_package) }
  let_it_be(:package_file) { package.package_files.first }

  let(:package_file_name) { package_file.file_name }
  let(:params) { {} }

  shared_examples 'package file finder examples' do
    it { is_expected.to eq(package_file) }

    context 'with file_name_like' do
      let(:package_file_name) { package_file.file_name.upcase }
      let(:params) { { with_file_name_like: true } }

      it { is_expected.to eq(package_file) }
    end
  end

  shared_examples 'not returning pending_destruction package files' do
    let_it_be(:recent_package_file_pending_destruction) do
      create(:package_file, :pending_destruction, package: package, file_name: package_file.file_name)
    end

    it 'returns the correct package file' do
      expect(package.package_files.last).to eq(recent_package_file_pending_destruction)

      expect(subject).to eq(package_file)
    end
  end

  describe '#execute' do
    subject { described_class.new(package, package_file_name, params).execute }

    it_behaves_like 'package file finder examples'

    it_behaves_like 'not returning pending_destruction package files'

    context 'with unknown file_name' do
      let(:package_file_name) { 'unknown.jpg' }

      it { expect(subject).to be_nil }
    end
  end

  describe '#execute!' do
    subject { described_class.new(package, package_file_name, params).execute! }

    it_behaves_like 'package file finder examples'

    it_behaves_like 'not returning pending_destruction package files'

    context 'with unknown file_name' do
      let(:package_file_name) { 'unknown.jpg' }

      it { expect { subject }.to raise_error(ActiveRecord::RecordNotFound) }
    end
  end
end
