# frozen_string_literal: true
require 'spec_helper'

describe Packages::MavenPackageFinder do
  let(:project) { create(:project) }
  let(:package) { create(:maven_package, project: project) }

  describe '#execute!' do
    it 'returns a package' do
      finder = described_class.new(project, package.maven_metadatum.path)

      expect(finder.execute!).to eq(package)
    end

    it 'raises an error' do
      finder = described_class.new(project, 'com/example/my-app/1.0-SNAPSHOT')

      expect { finder.execute! }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
