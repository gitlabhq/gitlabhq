# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Packages::Maven::PackageFinder, feature_category: :package_registry do
  let_it_be(:user) { create(:user) }
  let_it_be_with_refind(:group) { create(:group) }
  let_it_be_with_reload(:project) { create(:project, namespace: group) }
  let_it_be_with_refind(:package) { create(:maven_package, project: project) }

  let(:param_path) { nil }
  let(:project_or_group) { nil }
  let(:param_order_by_package_file) { false }
  let(:finder) { described_class.new(user, project_or_group, path: param_path, order_by_package_file: param_order_by_package_file) }

  shared_context 'with FF maven_extract_package_model disabled' do
    # It's required to turn off the FF when using the `maven_package_legacy` factory,
    # since its associations depend on the FF status.
    before do
      stub_feature_flags(maven_extract_package_model: false)
    end

    let!(:package) { create(:maven_package_legacy, project: project, name: FFaker::Lorem.word) }
  end

  describe '#execute' do
    subject { finder.execute }

    shared_examples 'handling valid and invalid paths' do
      context 'with a valid path' do
        let(:param_path) { package.maven_metadatum.path }

        it { is_expected.to include(package) }
      end

      context 'with an invalid path' do
        let(:param_path) { 'com/example/my-app/1.0-SNAPSHOT' }

        it 'returns an empty array' do
          is_expected.to be_empty
        end
      end

      context 'with an uninstallable package' do
        let(:param_path) { package.maven_metadatum.path }

        before do
          package.update_column(:status, :error)
        end

        it 'returns an empty array' do
          is_expected.to be_empty
        end
      end
    end

    context 'within the project' do
      let(:project_or_group) { project }

      it_behaves_like 'handling valid and invalid paths'

      context 'with FF maven_extract_package_model disabled' do
        include_context 'with FF maven_extract_package_model disabled' do
          it_behaves_like 'handling valid and invalid paths'
        end
      end
    end

    context 'within a group' do
      let(:project_or_group) { group }

      it_behaves_like 'handling valid and invalid paths'

      context 'with FF maven_extract_package_model disabled' do
        include_context 'with FF maven_extract_package_model disabled' do
          it_behaves_like 'handling valid and invalid paths'
        end
      end

      context 'when the FF maven_remove_permissions_check_from_finder disabled' do
        before do
          stub_feature_flags(maven_remove_permissions_check_from_finder: false)
        end

        it 'returns an empty array' do
          is_expected.to be_empty
        end

        context 'when a user is assigned the developer role' do
          before do
            group.add_developer(user)
          end

          it_behaves_like 'handling valid and invalid paths'
        end

        context 'with FF maven_extract_package_model disabled' do
          include_context 'with FF maven_extract_package_model disabled' do
            it 'returns an empty array' do
              is_expected.to be_empty
            end

            context 'when a user is assigned the developer role' do
              before do
                group.add_developer(user)
              end

              it_behaves_like 'handling valid and invalid paths'
            end
          end
        end
      end
    end

    context 'across all projects' do
      it 'returns an empty array' do
        is_expected.to be_empty
      end

      context 'with FF maven_extract_package_model disabled' do
        include_context 'with FF maven_extract_package_model disabled' do
          it 'returns an empty array' do
            is_expected.to be_empty
          end
        end
      end
    end

    context 'versionless maven-metadata.xml package' do
      let_it_be(:sub_group1) { create(:group, parent: group) }
      let_it_be(:sub_group2) { create(:group, parent: group) }
      let_it_be(:project1) { create(:project, group: sub_group1) }
      let_it_be(:project2) { create(:project, group: sub_group2) }
      let_it_be(:project3) { create(:project, group: sub_group1) }
      let_it_be(:package_name) { 'foo' }
      let_it_be(:package1) { create(:maven_package, project: project1, name: package_name, version: nil) }
      let_it_be(:package2) { create(:maven_package, project: project2, name: package_name, version: nil) }
      let_it_be(:package3) { create(:maven_package, project: project3, name: package_name, version: nil) }
      let_it_be(:package_file) { create(:package_file, :xml, package: package2) }

      let(:project_or_group) { group }
      let(:param_path) { package_name }

      before do
        sub_group1.add_developer(user)
        sub_group2.add_developer(user)
      end

      context 'without order by package file' do
        it { is_expected.to match_array([package1, package2, package3]) }
      end

      context 'with order by package file' do
        let(:param_order_by_package_file) { true }

        it { expect(subject.last).to eq(package2) }
      end

      context 'with FF maven_extract_package_model disabled' do
        include_context 'with FF maven_extract_package_model disabled' do
          let_it_be(:package_name) { FFaker::Lorem.word }

          let!(:package1) { create(:maven_package_legacy, project: project1, name: package_name, version: nil) }
          let!(:package2) { create(:maven_package_legacy, project: project2, name: package_name, version: nil) }
          let!(:package3) { create(:maven_package_legacy, project: project3, name: package_name, version: nil) }
          let!(:package_file) { create(:package_file, :xml, package: package2) }

          context 'without order by package file' do
            it { is_expected.to match_array([package1, package2, package3]) }
          end

          context 'with order by package file' do
            let(:param_order_by_package_file) { true }

            it { expect(subject.last).to eq(package2) }
          end
        end
      end
    end

    context 'with anonymous access to public registry in private group/project' do
      let(:project_or_group) { group }
      let(:user) { nil }

      before do
        [group, project].each do |entity|
          entity.update_column(:visibility_level, Gitlab::VisibilityLevel.const_get(:PRIVATE, false))
        end
        project.project_feature.update!(package_registry_access_level: ::ProjectFeature::PUBLIC)

        stub_feature_flags(maven_remove_permissions_check_from_finder: false)
      end

      it_behaves_like 'handling valid and invalid paths'

      context 'with FF maven_extract_package_model disabled' do
        include_context 'with FF maven_extract_package_model disabled' do
          it_behaves_like 'handling valid and invalid paths'
        end
      end
    end
  end

  it 'uses CTE in the query' do
    sql = described_class.new(user, group, path: package.maven_metadatum.path).send(:packages).to_sql

    expect(sql).to include('WITH "maven_metadata_by_path" AS')
  end
end
