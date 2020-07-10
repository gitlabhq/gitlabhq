# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Packages::PackageFinder do
  let_it_be(:project) { create(:project) }
  let_it_be(:maven_package) { create(:maven_package, project: project) }

  describe '#execute' do
    let(:package_id) { maven_package.id }

    subject { described_class.new(project, package_id).execute }

    it { is_expected.to eq(maven_package) }

    context 'processing packages' do
      let_it_be(:nuget_package) { create(:nuget_package, project: project, name: Packages::Nuget::CreatePackageService::TEMPORARY_PACKAGE_NAME) }
      let(:package_id) { nuget_package.id }

      it 'are not returned' do
        expect { subject }.to raise_exception(ActiveRecord::RecordNotFound)
      end
    end
  end
end
