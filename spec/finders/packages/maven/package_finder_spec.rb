# frozen_string_literal: true
require 'spec_helper'

RSpec.describe ::Packages::Maven::PackageFinder do
  let(:user)    { create(:user) }
  let(:group)   { create(:group) }
  let(:project) { create(:project, namespace: group) }
  let(:package) { create(:maven_package, project: project) }

  before do
    group.add_developer(user)
  end

  describe '#execute!' do
    context 'within the project' do
      it 'returns a package' do
        finder = described_class.new(package.maven_metadatum.path, user, project: project)

        expect(finder.execute!).to eq(package)
      end

      it 'raises an error' do
        finder = described_class.new('com/example/my-app/1.0-SNAPSHOT', user, project: project)

        expect { finder.execute! }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'across all projects' do
      it 'returns a package' do
        finder = described_class.new(package.maven_metadatum.path, user)

        expect(finder.execute!).to eq(package)
      end

      it 'raises an error' do
        finder = described_class.new('com/example/my-app/1.0-SNAPSHOT', user)

        expect { finder.execute! }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'within a group' do
      it 'returns a package' do
        finder = described_class.new(package.maven_metadatum.path, user, group: group)

        expect(finder.execute!).to eq(package)
      end

      it 'raises an error' do
        finder = described_class.new('com/example/my-app/1.0-SNAPSHOT', user, group: group)

        expect { finder.execute! }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
