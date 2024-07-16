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

  describe '#execute' do
    let(:query) { "#{conan_package.name.split('/').first[0, 3]}%" }
    let(:finder) { described_class.new(user, params) }
    let(:params) { { query: query } }

    subject { finder.execute }

    where(:visibility, :role, :packages_visible) do
      :private  | :maintainer | true
      :private  | :developer  | true
      :private  | :reporter   | true
      :private  | :guest      | false
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

        let(:query) { "#{conan_package.name}/#{conan_package3.version}" }

        it 'matches the correct package' do
          expect(subject).to match_array([conan_package3])
        end
      end

      context 'with nil query' do
        let(:query) { nil }

        it 'returns an empty array' do
          expect(subject).to match_array([])
        end
      end

      context 'without name' do
        let(:query) { "/1.0.0" }

        it 'returns an empty array' do
          expect(subject).to match_array([])
        end
      end

      context 'with a different project' do
        let_it_be(:project) { private_project }

        it { is_expected.to match_array([private_package]) }
      end
    end
  end
end
