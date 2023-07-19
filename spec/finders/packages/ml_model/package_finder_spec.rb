# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Packages::MlModel::PackageFinder, feature_category: :mlops do
  let_it_be(:project) { create(:project) }
  let_it_be(:package) { create(:ml_model_package, project: project) }

  let(:package_name) { package.name }
  let(:package_version) { package.version }

  describe '#execute!' do
    subject(:find_package) { described_class.new(project).execute!(package_name, package_version) }

    it 'finds package by name and version' do
      expect(find_package).to eq(package)
    end

    it 'ignores packages with same name but different version' do
      create(:ml_model_package, project: project, name: package.name, version: '3.1.4')

      expect(find_package).to eq(package)
    end

    context 'when package name+version does not exist' do
      let(:package_name) { 'a_package_that_does_not_exist' }

      it 'raises ActiveRecord::RecordNotFound' do
        expect { find_package }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when package exists but is marked for destruction' do
      let_it_be(:invalid_package) do
        create(:ml_model_package, project: project, status: :pending_destruction)
      end

      let(:package_name) { invalid_package.name }
      let(:package_version) { invalid_package.version }

      it 'raises ActiveRecord::RecordNotFound' do
        expect { find_package }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when package name+version does not exist but it is not ml_model' do
      let_it_be(:another_package) { create(:generic_package, project: project) }

      let(:package_name) { another_package.name }
      let(:package_version) { another_package.version }

      it 'raises ActiveRecord::RecordNotFound' do
        expect { find_package }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
