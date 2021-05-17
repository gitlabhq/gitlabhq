# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Packages::PackagesFinder do
  let_it_be(:project) { create(:project) }
  let_it_be(:maven_package) { create(:maven_package, project: project, created_at: 2.days.ago, name: 'maven', version: '2.0.0') }
  let_it_be(:conan_package) { create(:conan_package, project: project, created_at: 1.day.ago, name: 'conan', version: '1.0.0') }

  describe '#execute' do
    let(:params) { {} }

    subject { described_class.new(project, params).execute }

    context 'with package_type' do
      let_it_be(:npm_package1) { create(:npm_package, project: project) }
      let_it_be(:npm_package2) { create(:npm_package, project: project) }

      context 'conan packages' do
        let(:params) { { package_type: 'conan' } }

        it { is_expected.to eq([conan_package]) }
      end

      context 'npm packages' do
        let(:params) { { package_type: 'npm' } }

        it { is_expected.to match_array([npm_package1, npm_package2]) }
      end
    end

    context 'with order_by' do
      context 'by default is created_at' do
        it { is_expected.to eq([maven_package, conan_package]) }
      end

      context 'order by name' do
        let(:params) { { order_by: 'name' } }

        it { is_expected.to eq([conan_package, maven_package]) }
      end

      context 'order by version' do
        let(:params) { { order_by: 'version' } }

        it { is_expected.to eq([conan_package, maven_package]) }
      end

      context 'order by type' do
        let(:params) { { order_by: 'type' } }

        it { is_expected.to eq([maven_package, conan_package]) }
      end
    end

    context 'with sort' do
      context 'by default is ascending' do
        it { is_expected.to eq([maven_package, conan_package]) }
      end

      context 'can sort descended' do
        let(:params) { { sort: 'desc' } }

        it { is_expected.to eq([conan_package, maven_package]) }
      end
    end

    context 'with package_name' do
      let(:params) { { package_name: 'maven' } }

      it { is_expected.to eq([maven_package]) }
    end

    context 'with nil params' do
      it { is_expected.to match_array([conan_package, maven_package]) }
    end

    context 'with processing packages' do
      let_it_be(:nuget_package) { create(:nuget_package, :processing, project: project) }

      it { is_expected.to match_array([conan_package, maven_package]) }
    end

    it_behaves_like 'concerning versionless param'
    it_behaves_like 'concerning package statuses'
  end
end
