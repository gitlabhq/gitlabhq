# frozen_string_literal: true
require 'spec_helper'

RSpec.describe ::Packages::Conan::PackageFinder, feature_category: :package_registry do
  using RSpec::Parameterized::TableSyntax

  let_it_be_with_reload(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:private_project) { create(:project, :private) }

  let_it_be(:conan_package) { create(:conan_package, project: project) }
  let_it_be(:conan_package2) { create(:conan_package, project: project) }
  let_it_be(:errored_package) { create(:conan_package, :error, project: project) }
  let_it_be(:private_package) { create(:conan_package, project: private_project) }

  describe '#initialize', :aggregate_failures do
    let(:query) { 'a*p*a/1.*.3@name*ace1+pr*ct-1/stable' }
    let(:params) { { query: query } }

    subject { described_class.new(user, params) }

    it 'uses sql wildcards' do
      expect(subject.send(:name)).to eq('a%p%a')
      expect(subject.send(:version)).to eq('1.%.3')
      expect(subject.send(:username)).to eq('name%ace1+pr%ct-1')
    end

    context 'with query containing special characters' do
      let(:query) { '\   /\n\\    "     ' }

      it 'escapes sql characters' do
        expect(subject.send(:name)).to eq('\\\\   ')
        expect(subject.send(:version)).to eq('\\\\n\\\\    "     ')
        expect(subject.send(:username)).to be_nil
      end
    end
  end

  describe '#execute' do
    context 'without package user name' do
      let(:query) { "#{conan_package.name.split('/').first[0, 3]}*" }
      let(:finder) { described_class.new(user, params) }
      let(:params) { { query: query } }

      subject { finder.execute }

      where(:visibility, :role, :packages_visible) do
        :private  | :maintainer | true
        :private  | :developer  | true
        :private  | :reporter   | true
        :private  | :guest      | true
        :private  | :anonymous  | false

        :internal | :maintainer | true
        :internal | :developer  | true
        :internal | :reporter   | true
        :internal | :guest      | true
        :internal | :anonymous  | false

        :public   | :maintainer | true
        :public   | :developer  | true
        :public   | :reporter   | true
        :public   | :guest      | true
        :public   | :anonymous  | true
      end

      with_them do
        let(:expected_packages) { packages_visible ? [conan_package2, conan_package] : [] }
        let(:user) { role == :anonymous ? nil : super() }

        before do
          project.update_column(:visibility_level, Gitlab::VisibilityLevel.string_options[visibility.to_s])
          project.add_member(user, role) unless role == :anonymous
        end

        it { is_expected.to eq(expected_packages) }
      end

      context 'with project' do
        let(:finder) { described_class.new(user, params, project: project) }

        it { is_expected.to match_array([conan_package2, conan_package]) }

        it 'respects the limit' do
          stub_const("#{described_class}::MAX_PACKAGES_COUNT", 1)

          expect(subject).to match_array([conan_package2])
        end

        context 'with version' do
          let_it_be(:conan_package3) do
            create(:conan_package, project: project, name: conan_package.name, version: '1.2.3')
          end

          let(:query) { "#{conan_package3.name}/#{conan_package3.version}" }

          it 'matches the correct package' do
            expect(subject).to match_array([conan_package3])
          end
        end

        context 'with partial version' do
          let_it_be(:conan_package3) do
            create(:conan_package, project: project, name: conan_package.name, version: '1.2.3')
          end

          let(:query) { "#{conan_package3.name}/1.*.3" }

          it 'matches the correct package' do
            expect(subject).to match_array([conan_package3])
          end
        end

        context 'with nil query' do
          let(:query) { nil }

          it { is_expected.to be_empty }
        end

        context 'without name' do
          let(:query) { "/1.0.0" }

          it { is_expected.to be_empty }
        end

        context 'with a wildcard name and a wildcard version' do
          let(:query) { '*/*' }

          it { is_expected.to be_empty }
        end

        context 'with a different project' do
          let_it_be(:project) { private_project }

          it { is_expected.to match_array([private_package]) }
        end
      end

      context 'when allow_guest_plus_roles_to_pull_packages is disabled' do
        before_all do
          project.update_column(:visibility_level, Gitlab::VisibilityLevel.string_options['private'])
          project.add_guest(user)
        end

        before do
          stub_feature_flags(allow_guest_plus_roles_to_pull_packages: false)
        end

        it { is_expected.to be_empty }
      end
    end

    context 'with package user name' do
      let(:query) { "#{conan_package.name.split('/').first[0, 3]}*" }
      let(:finder) { described_class.new(user, params) }
      let(:params) { { query: package.conan_recipe } }

      subject { finder.execute }

      context 'with a valid query and user with permissions' do
        before do
          allow_next_instance_of(described_class) do |service|
            allow(service).to receive(:can_access_project_package?).and_return(true)
          end
        end

        context "with conan_recipe as query" do
          it 'returns the correct package' do
            [conan_package, conan_package2].each do |package|
              params = { query: package.conan_recipe }
              result = described_class.new(user, params).execute
              expect(result).to match_array([package])
            end
          end
        end

        context "without version in query" do
          it 'returns the correct package' do
            [conan_package, conan_package2].each do |package|
              params = { query: package.conan_recipe.sub(package.version, '') }
              result = described_class.new(user, params).execute
              expect(result).to match_array([package])
            end
          end
        end

        context 'with a user without permissions' do
          before do
            allow_next_instance_of(described_class) do |service|
              allow(service).to receive(:can_access_project_package?).and_return(false)
            end
          end

          it 'returns an empty array' do
            params = { query: conan_package.conan_recipe }
            result = described_class.new(user, params).execute
            expect(result).to be_empty
          end
        end

        context 'with a specified project' do
          it 'return the pacakge from the specified project' do
            params = { query: private_package.conan_recipe }
            result = described_class.new(user, params, project: private_project).execute
            expect(result).to match_array([private_package])
          end
        end
      end
    end
  end
end
