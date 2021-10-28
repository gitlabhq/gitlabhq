# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Packages::PackageFinder do
  let_it_be(:project) { create(:project) }
  let_it_be_with_refind(:maven_package) { create(:maven_package, project: project) }

  describe '#execute' do
    let(:package_id) { maven_package.id }

    subject { described_class.new(project, package_id).execute }

    it { is_expected.to eq(maven_package) }

    context 'with non-displayable package' do
      before do
        maven_package.update_column(:status, 1)
      end

      it 'raises an exception' do
        expect { subject }.to raise_exception(ActiveRecord::RecordNotFound)
      end
    end

    context 'processing packages' do
      let_it_be(:nuget_package) { create(:nuget_package, :processing, project: project) }

      let(:package_id) { nuget_package.id }

      it 'are not returned' do
        expect { subject }.to raise_exception(ActiveRecord::RecordNotFound)
      end
    end

    context 'with pipelines' do
      let_it_be(:build_info) { create(:package_build_info, :with_pipeline, package: maven_package) }

      it 'preloads the pipelines' do
        expect(::Packages::Package).to receive(:preload_pipelines).and_call_original
        expect(::Packages::Package).not_to receive(:including_build_info)

        expect(subject).to eq(maven_package)
      end

      context 'with packages_remove_cross_joins_to_pipelines disabled' do
        before do
          stub_feature_flags(packages_remove_cross_joins_to_pipelines: false)
        end

        it 'includes the pipelines' do
          expect(::Packages::Package).to receive(:including_build_info).and_call_original
          expect(::Packages::Package).not_to receive(:preload_pipelines)

          expect(subject).to eq(maven_package)
        end
      end
    end
  end
end
