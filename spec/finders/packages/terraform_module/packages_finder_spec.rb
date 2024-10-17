# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Packages::TerraformModule::PackagesFinder, feature_category: :package_registry do
  let_it_be(:project) { create(:project) }
  let_it_be_with_reload(:package1) { create(:terraform_module_package, project: project, version: '1.0.0') }
  let_it_be(:package2) { create(:terraform_module_package, project: project, version: '2.0.0', name: package1.name) }

  let(:params) { {} }

  subject { described_class.new(project, params).execute }

  describe '#execute' do
    context 'without project' do
      let(:project) { nil }

      it { is_expected.to be_empty }

      context 'with package_name' do
        let(:params) { { package_name: package1.name } }

        it { is_expected.to be_empty }
      end
    end

    context 'without package_name' do
      let(:params) { { package_name: nil } }

      it { is_expected.to be_empty }
    end

    context 'with package_name' do
      let(:params) { { package_name: package1.name } }

      it 'returns packages with the given name ordered by version desc' do
        is_expected.to eq([package2, package1])
      end

      context 'with package_version' do
        let(:params) { { package_name: package1.name, package_version: package1.version } }

        it { is_expected.to eq([package1]) }
      end

      context 'when package is not installable' do
        before do
          package1.update_column(:status, 3)
        end

        it { is_expected.to eq([package2]) }
      end

      context 'when package has no version' do
        before do
          package1.update_column(:version, nil)
        end

        it { is_expected.to eq([package2]) }
      end

      context 'when package is not a terraform module' do
        before do
          package1.update_column(:package_type, 1)
        end

        it { is_expected.to eq([package2]) }
      end
    end

    context 'when terraform_extract_terraform_package_model is disabled' do
      # rubocop:disable Cop/AvoidBecomes -- implementing inheritance for Terraform packages https://gitlab.com/gitlab-org/gitlab/-/issues/435834
      let_it_be_with_reload(:package1) { package1.becomes(::Packages::Package) }
      let_it_be(:package2) { package2.becomes(::Packages::Package) }
      # rubocop:enable Cop/AvoidBecomes

      before do
        stub_feature_flags(terraform_extract_terraform_package_model: false)
      end

      context 'without project' do
        let(:project) { nil }

        it { is_expected.to be_empty }

        context 'with package_name' do
          let(:params) { { package_name: package1.name } }

          it { is_expected.to be_empty }
        end
      end

      context 'without package_name' do
        let(:params) { { package_name: nil } }

        it { is_expected.to be_empty }
      end

      context 'with package_name' do
        let(:params) { { package_name: package1.name } }

        it 'returns packages with the given name ordered by version desc' do
          is_expected.to eq([package2, package1])
        end

        context 'with package_version' do
          let(:params) { { package_name: package1.name, package_version: package1.version } }

          it { is_expected.to eq([package1]) }
        end

        context 'when package is not installable' do
          before do
            package1.update_column(:status, 3)
          end

          it { is_expected.to eq([package2]) }
        end

        context 'when package has no version' do
          before do
            package1.update_column(:version, nil)
          end

          it { is_expected.to eq([package2]) }
        end

        context 'when package is not a terraform module' do
          before do
            package1.update_column(:package_type, 1)
          end

          it { is_expected.to eq([package2]) }
        end
      end
    end
  end
end
