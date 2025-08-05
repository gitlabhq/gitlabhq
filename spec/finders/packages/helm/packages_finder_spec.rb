# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Packages::Helm::PackagesFinder, feature_category: :package_registry do
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

      context 'with max_packages_count set to 2' do
        before do
          allow(::Gitlab::CurrentSettings)
            .to receive_message_chain(:package_registry, :fetch)
            .with('helm_max_packages_count', anything)
            .and_return(2)
        end

        subject(:limited_packages_finder) { finder.execute }

        it 'returns only 2 packages' do
          packages = limited_packages_finder

          aggregate_failures do
            expect(packages.size).to eq(2)
            expect(packages).to all(be_a(Packages::Helm::Package))
            expect(packages).to all(have_attributes(project_id: project.id))
          end
        end

        context 'with with_recent_limit as false' do
          let(:finder) { described_class.new(project, channel, with_recent_limit: false) }

          it 'returns all the packages' do
            packages = limited_packages_finder

            expect(packages.size).to eq(4)
          end
        end
      end
    end
  end
end
