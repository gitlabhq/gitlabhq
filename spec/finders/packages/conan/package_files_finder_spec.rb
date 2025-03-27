# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Conan::PackageFilesFinder, feature_category: :package_registry do
  let_it_be(:package) { create(:conan_package) }
  let_it_be(:aditional_recipe_revision) { create(:conan_recipe_revision, package: package) }

  let_it_be(:package_file_without_revision) do
    create(:conan_package_file, :conan_recipe_file,
      package: package, conan_recipe_revision: nil)
  end

  let_it_be(:aditional_package_file) do
    create(:conan_package_file, :conan_recipe_file, package: package,
      conan_recipe_revision: aditional_recipe_revision)
  end

  let(:package_files) { package.package_files }
  let(:params) { {} }
  let(:finder) { described_class.new(package, params) }

  let(:package_file) do
    package.package_files.find { |f| f.conan_file_metadatum.recipe_revision_value != aditional_recipe_revision }
  end

  describe '#execute' do
    subject(:found_package_files) { finder.execute }

    it { is_expected.to be_a(ActiveRecord::Relation).and match_array(package_files) }

    context 'with conan_file_type' do
      let(:params) { { conan_file_type: :recipe_file } }

      it 'returns only files with recipe_file type' do
        expect(found_package_files).to all(have_attributes(conan_file_type: 'recipe_file'))
      end
    end

    context 'with conan_package_reference' do
      let_it_be(:package_file) { package.package_files.find_by(file_name: 'conaninfo.txt') }
      let(:conan_package_reference) { package_file.conan_file_metadatum.package_reference_value }
      let(:params) { { conan_package_reference: conan_package_reference } }

      let(:expected_package_files) do
        package_files.select do |file|
          file.conan_file_metadatum.package_reference_value == conan_package_reference
        end
      end

      it { expect(found_package_files).to match_array(expected_package_files) }
    end

    context 'with file_name' do
      let(:package_file_name) { package_file.file_name }
      let(:params) { { file_name: package_file_name } }

      let(:expected_package_files) do
        package_files.select do |file|
          file.file_name == package_file_name
        end
      end

      it { is_expected.to match_array(expected_package_files) }
    end

    context 'with file_name_like' do
      let(:package_file_name) { package_file.file_name.upcase }
      let(:params) { { file_name: package_file_name, with_file_name_like: true } }

      let(:expected_package_files) do
        package_files.select do |file|
          file.file_name.upcase == package_file_name
        end
      end

      it { is_expected.to match_array(expected_package_files) }
    end

    context 'with recipe_revision' do
      let(:params) { { recipe_revision: recipe_revision_value } }

      context 'with default revision' do
        let(:recipe_revision_value) { Packages::Conan::FileMetadatum::DEFAULT_REVISION }

        it 'returns package files without recipe revision' do
          expect(found_package_files).to match_array([package_file_without_revision])
        end
      end

      context 'with specific revision' do
        let(:recipe_revision_value) { package_file.conan_file_metadatum.recipe_revision_value }
        let(:expected_package_files) do
          package_files.select do |file|
            file.conan_file_metadatum.recipe_revision_value == recipe_revision_value
          end
        end

        it 'returns package files with matching recipe revision' do
          expect(found_package_files).to match_array(expected_package_files)
        end
      end
    end

    context 'when no files exist' do
      let_it_be(:package) { create(:conan_package, without_package_files: true) }

      it { is_expected.to be_empty }
    end
  end
end
