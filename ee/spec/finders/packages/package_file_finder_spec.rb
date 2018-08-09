# frozen_string_literal: true
require 'spec_helper'

describe Packages::PackageFileFinder do
  let(:package) { create(:maven_package) }
  let(:package_file) { package.package_files.first }

  describe '#execute!' do
    it 'returns a package file' do
      finder = described_class.new(package, package_file.file_name)

      expect(finder.execute!).to eq(package_file)
    end

    it 'raises an error' do
      finder = described_class.new(package, 'unknown.jpg')

      expect { finder.execute! }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
