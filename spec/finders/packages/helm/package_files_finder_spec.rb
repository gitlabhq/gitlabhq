# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Packages::Helm::PackageFilesFinder do
  let_it_be(:project1) { create(:project) }
  let_it_be(:project2) { create(:project) }
  let_it_be(:helm_package) { create(:helm_package, project: project1) }
  let_it_be(:helm_package_file) { helm_package.package_files.first }
  let_it_be(:debian_package) { create(:debian_package, project: project1) }

  describe '#execute' do
    let(:project) { project1 }
    let(:channel) { 'stable' }
    let(:params) { {} }

    subject { described_class.new(project, channel, params).execute }

    context 'with empty params' do
      it { is_expected.to match_array([helm_package_file]) }
    end

    context 'with another project' do
      let(:project) { project2 }

      it { is_expected.to match_array([]) }
    end

    context 'with another channel' do
      let(:channel) { 'staging' }

      it { is_expected.to match_array([]) }
    end

    context 'with file_name' do
      let(:params) { { file_name: helm_package_file.file_name } }

      it { is_expected.to match_array([helm_package_file]) }
    end

    context 'with another file_name' do
      let(:params) { { file_name: 'foobar.tgz' } }

      it { is_expected.to match_array([]) }
    end
  end
end
