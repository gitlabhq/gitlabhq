# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Packages::Maven::PackageFinder do
  let_it_be(:user)    { create(:user) }
  let_it_be(:group)   { create(:group) }
  let_it_be(:project) { create(:project, namespace: group) }
  let_it_be(:package) { create(:maven_package, project: project) }

  let(:param_path) { nil }
  let(:param_project) { nil }
  let(:param_group) { nil }
  let(:finder) { described_class.new(param_path, user, project: param_project, group: param_group) }

  before do
    group.add_developer(user)
  end

  describe '#execute!' do
    subject { finder.execute! }

    shared_examples 'handling valid and invalid paths' do
      context 'with a valid path' do
        let(:param_path) { package.maven_metadatum.path }

        it { is_expected.to eq(package) }
      end

      context 'with an invalid path' do
        let(:param_path) { 'com/example/my-app/1.0-SNAPSHOT' }

        it 'raises an error' do
          expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

    context 'within the project' do
      let(:param_project) { project }

      it_behaves_like 'handling valid and invalid paths'
    end

    context 'within a group' do
      let(:param_group) { group }

      it_behaves_like 'handling valid and invalid paths'
    end

    context 'across all projects' do
      it 'raises an error' do
        expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'versionless maven-metadata.xml package' do
      let_it_be(:sub_group1) { create(:group, parent: group) }
      let_it_be(:sub_group2)   { create(:group, parent: group) }
      let_it_be(:project1) { create(:project, group: sub_group1) }
      let_it_be(:project2) { create(:project, group: sub_group2) }
      let_it_be(:project3) { create(:project, group: sub_group1) }
      let_it_be(:package_name) { 'foo' }
      let_it_be(:package1) { create(:maven_package, project: project1, name: package_name, version: nil) }
      let_it_be(:package2) { create(:maven_package, project: project2, name: package_name, version: nil) }
      let_it_be(:package3) { create(:maven_package, project: project3, name: package_name, version: nil) }

      let(:param_group) { group }
      let(:param_path) { package_name }

      before do
        sub_group1.add_developer(user)
        sub_group2.add_developer(user)
        # the package with the most recently published file should be returned
        create(:package_file, :xml, package: package2)
      end

      it { is_expected.to eq(package2) }
    end
  end
end
