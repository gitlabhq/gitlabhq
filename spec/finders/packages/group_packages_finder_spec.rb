# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::GroupPackagesFinder do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:group) { create(:group) }
  let_it_be_with_reload(:project) { create(:project, namespace: group, builds_access_level: ProjectFeature::PRIVATE, merge_requests_access_level: ProjectFeature::PRIVATE) }

  let(:add_user_to_group) { true }

  before do
    group.add_developer(user) if add_user_to_group
  end

  describe '#execute' do
    let(:params) { { exclude_subgroups: false } }

    subject { described_class.new(user, group, params).execute }

    shared_examples 'with package type' do |package_type|
      let(:params) { { exclude_subgroups: false, package_type: package_type } }

      it { is_expected.to match_array([send("package_#{package_type}")]) }
    end

    def self.package_types
      @package_types ||= Packages::Package.package_types.keys
    end

    context 'group has packages' do
      let_it_be(:package1) { create(:maven_package, project: project) }
      let_it_be(:package2) { create(:maven_package, project: project) }
      let_it_be(:package3) { create(:maven_package) }

      it { is_expected.to match_array([package1, package2]) }

      context 'subgroup has packages' do
        let_it_be_with_reload(:subgroup) { create(:group, parent: group) }
        let_it_be_with_reload(:subproject) { create(:project, namespace: subgroup, builds_access_level: ProjectFeature::PRIVATE, merge_requests_access_level: ProjectFeature::PRIVATE) }
        let_it_be(:package4) { create(:npm_package, project: subproject) }

        it { is_expected.to match_array([package1, package2, package4]) }

        context 'excluding subgroups' do
          let(:params) { { exclude_subgroups: true } }

          it { is_expected.to match_array([package1, package2]) }
        end

        context 'permissions' do
          let(:add_user_to_group) { false }

          where(:role, :project_visibility, :repository_visibility, :packages_returned) do
            :anonymous  | :public  | :enabled | :all
            :guest      | :public  | :enabled | :all
            :reporter   | :public  | :enabled | :all
            :developer  | :public  | :enabled | :all
            :maintainer | :public  | :enabled | :all
            :anonymous  | :public  | :private | :none
            :guest      | :public  | :private | :all
            :reporter   | :public  | :private | :all
            :developer  | :public  | :private | :all
            :maintainer | :public  | :private | :all
            :anonymous  | :private | :enabled | :none
            :guest      | :private | :enabled | :none
            :reporter   | :private | :enabled | :all
            :developer  | :private | :enabled | :all
            :maintainer | :private | :enabled | :all
            :anonymous  | :private | :private | :none
            :guest      | :private | :private | :none
            :reporter   | :private | :private | :all
            :developer  | :private | :private | :all
            :maintainer | :private | :private | :all
          end

          with_them do
            let(:expected_packages) do
              case packages_returned
              when :all
                [package1, package2, package4]
              when :none
                []
              end
            end

            before do
              subgroup.update!(visibility: project_visibility.to_s)
              group.update!(visibility: project_visibility.to_s)
              project.update!(
                visibility: project_visibility.to_s,
                repository_access_level: repository_visibility.to_s
              )
              subproject.update!(
                visibility: project_visibility.to_s,
                repository_access_level: repository_visibility.to_s
              )

              unless role == :anonymous
                project.add_user(user, role)
                subproject.add_user(user, role)
              end
            end

            it { is_expected.to match_array(expected_packages) }
          end
        end

        context 'avoid N+1 query' do
          it 'avoids N+1 database queries' do
            count = ActiveRecord::QueryRecorder.new { subject }
                                               .count

            Packages::Package.package_types.keys.each do |package_type|
              create("#{package_type}_package", project: create(:project, namespace: subgroup))
            end

            expect { described_class.new(user, group, params).execute }.not_to exceed_query_limit(count)
          end
        end
      end

      context 'when there are processing packages' do
        let_it_be(:package4) { create(:nuget_package, :processing, project: project) }

        it { is_expected.to match_array([package1, package2]) }
      end

      context 'with package_name' do
        let_it_be(:named_package) { create(:maven_package, project: project, name: 'maven') }

        let(:params) { { package_name: package_name } }

        context 'as complete name' do
          let(:package_name) { 'maven' }

          it { is_expected.to eq([named_package]) }
        end

        %w[aven mav ave].each do |filter|
          context "for fuzzy filter #{filter}" do
            let(:package_name) { filter }

            it { is_expected.to eq([named_package]) }
          end
        end
      end

      it_behaves_like 'concerning versionless param'
      it_behaves_like 'concerning package statuses'
    end

    context 'group has package of all types' do
      package_types.each { |pt| let_it_be("package_#{pt}") { create("#{pt}_package", project: project) } }

      package_types.each do |package_type|
        it_behaves_like 'with package type', package_type
      end
    end

    context 'group has no packages' do
      it { is_expected.to be_empty }
    end

    context 'group is nil' do
      subject { described_class.new(user, nil).execute }

      it { is_expected.to be_empty}
    end

    context 'package type is nil' do
      let_it_be(:package1) { create(:maven_package, project: project) }

      subject { described_class.new(user, group, package_type: nil).execute }

      it { is_expected.to match_array([package1])}
    end

    context 'with invalid package_type' do
      let(:params) { { package_type: 'invalid_type' } }

      it { expect { subject }.to raise_exception(described_class::InvalidPackageTypeError) }
    end
  end
end
