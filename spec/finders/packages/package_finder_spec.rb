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
  end
end
