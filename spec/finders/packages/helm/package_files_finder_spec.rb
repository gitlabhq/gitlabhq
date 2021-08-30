# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Packages::Helm::PackageFilesFinder do
  let_it_be(:project1) { create(:project) }
  let_it_be(:project2) { create(:project) }
  let_it_be(:helm_package) { create(:helm_package, project: project1) }
  let_it_be(:helm_package_file1) { helm_package.package_files.first }
  let_it_be(:helm_package_file2) { create(:helm_package_file, package: helm_package) }
  let_it_be(:debian_package) { create(:debian_package, project: project1) }

  let(:project) { project1 }
  let(:channel) { 'stable' }
  let(:params) { {} }

  let(:service) { described_class.new(project, channel, params) }

  describe '#execute' do
    subject { service.execute }

    context 'with empty params' do
      it { is_expected.to eq([helm_package_file2, helm_package_file1]) }
    end

    context 'with another project' do
      let(:project) { project2 }

      it { is_expected.to eq([]) }
    end

    context 'with another channel' do
      let(:channel) { 'staging' }

      it { is_expected.to eq([]) }
    end

    context 'with matching file_name' do
      let(:params) { { file_name: helm_package_file1.file_name } }

      it { is_expected.to eq([helm_package_file2, helm_package_file1]) }
    end

    context 'with another file_name' do
      let(:params) { { file_name: 'foobar.tgz' } }

      it { is_expected.to eq([]) }
    end
  end

  describe '#most_recent!' do
    subject { service.most_recent! }

    it { is_expected.to eq(helm_package_file2) }
  end
end
