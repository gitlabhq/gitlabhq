# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Packages::Helm::PackagesFinder do
  let_it_be(:project1) { create(:project) }
  let_it_be(:project2) { create(:project) }
  let_it_be(:helm_package) { create(:helm_package, project: project1) }
  let_it_be(:npm_package) { create(:npm_package, project: project1) }
  let_it_be(:npm_package) { create(:npm_package, project: project2) }

  let(:project) { project1 }
  let(:channel) { 'stable' }
  let(:finder) { described_class.new(project, channel) }

  describe '#execute' do
    subject { finder.execute }

    context 'with project' do
      context 'with channel' do
        it { is_expected.to eq([helm_package]) }

        context 'ignores duplicate package files' do
          let_it_be(:package_file1) { create(:helm_package_file, package: helm_package) }
          let_it_be(:package_file2) { create(:helm_package_file, package: helm_package) }

          it { is_expected.to eq([helm_package]) }

          context 'let clients use select id' do
            subject { finder.execute.pluck_primary_key }

            it { is_expected.to eq([helm_package.id]) }
          end
        end
      end

      context 'with not existing channel' do
        let(:channel) { 'alpha' }

        it { is_expected.to be_empty }
      end

      context 'with no channel' do
        let(:channel) { nil }

        it { is_expected.to be_empty }
      end

      context 'with no helm packages' do
        let(:project) { project2 }

        it { is_expected.to be_empty }
      end
    end

    context 'with no project' do
      let(:project) { nil }

      it { is_expected.to be_empty }
    end

    context 'when the limit is hit' do
      let_it_be(:helm_package2) { create(:helm_package, project: project1) }
      let_it_be(:helm_package3) { create(:helm_package, project: project1) }
      let_it_be(:helm_package4) { create(:helm_package, project: project1) }

      before do
        stub_const("#{described_class}::MAX_PACKAGES_COUNT", 2)
      end

      it { is_expected.to eq([helm_package4, helm_package3]) }
    end
  end
end
