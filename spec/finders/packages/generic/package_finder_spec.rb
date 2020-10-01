# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Packages::Generic::PackageFinder do
  let_it_be(:project) { create(:project) }
  let_it_be(:package) { create(:generic_package, project: project) }

  describe '#execute!' do
    subject(:finder) { described_class.new(project) }

    it 'finds package by name and version' do
      found_package = finder.execute!(package.name, package.version)

      expect(found_package).to eq(package)
    end

    it 'ignores packages with same name but different version' do
      create(:generic_package, project: project, name: package.name, version: '3.1.4')

      found_package = finder.execute!(package.name, package.version)

      expect(found_package).to eq(package)
    end

    it 'raises ActiveRecord::RecordNotFound if package is not found' do
      expect { finder.execute!(package.name, '3.1.4') }
        .to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
