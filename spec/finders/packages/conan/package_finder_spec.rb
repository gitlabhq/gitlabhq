# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Packages::Conan::PackageFinder, feature_category: :package_registry do
  using RSpec::Parameterized::TableSyntax

  let_it_be_with_reload(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:private_project) { create(:project, :private) }

  let_it_be_with_reload(:conan_package) { create(:conan_package, project: project) }
  let_it_be(:conan_package2) { create(:conan_package, project: project) }
  let_it_be(:errored_package) { create(:conan_package, :error, project: project) }
  let_it_be(:private_package) { create(:conan_package, project: private_project) }

  let(:params) { { query: query } }
  let(:finder) { described_class.new(user, params) }
  let(:non_existent_username) { 'non_existing' }
  let(:non_existent_channel) { 'non_existing' }

  subject(:result) { finder.execute }

  describe '#initialize', :aggregate_failures do
    let(:query) { 'a*p*a/1.*.3@name*ace1+pr*ct-1/stable' }

    it 'uses sql wildcards' do
      expect(finder.send(:name)).to eq('a%p%a')
      expect(finder.send(:version)).to eq('1.%.3')
      expect(finder.send(:username)).to eq('name%ace1+pr%ct-1')
    end

    context 'with query containing special characters' do
      let(:query) { '\   /\n\\    "     ' }

      it 'escapes sql characters' do
        expect(finder.send(:name)).to eq('\\\\   ')
        expect(finder.send(:version)).to eq('\\\\n\\\\    "     ')
        expect(finder.send(:username)).to be_nil
      end
    end
  end

  describe '#execute' do
    context 'without package username and channel' do
      let(:query) { "#{conan_package.name[0, 3]}*" }

      it { is_expected.to eq([]) }

      context 'with project' do
        let(:finder) { described_class.new(user, params, project: project) }

        it { is_expected.to match_array([conan_package2, conan_package]) }

        it 'respects the limit' do
          stub_const("#{described_class}::MAX_PACKAGES_COUNT", 1)

          expect(result).to match_array([conan_package2])
        end

        context 'with version' do
          let_it_be(:conan_package3) do
            create(:conan_package, project: project, name: conan_package.name, version: '1.2.3')
          end

          let(:query) { "#{conan_package3.name}/#{conan_package3.version}" }

          it 'matches the correct package' do
            expect(result).to match_array([conan_package3])
          end
        end

        context 'with partial version' do
          let_it_be(:conan_package3) do
            create(:conan_package, project: project, name: conan_package.name, version: '1.2.3')
          end

          let(:query) { "#{conan_package3.name}/1.*.3" }

          it 'matches the correct package' do
            expect(result).to match_array([conan_package3])
          end
        end

        context 'with nil query' do
          let(:query) { nil }

          it { is_expected.to be_empty }
        end

        context 'without name' do
          let(:query) { '/1.0.0' }

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

        context 'with ignorecase' do
          let_it_be(:capitalized_name) { conan_package.name.capitalize }

          before_all do
            conan_package.update_column(:name, capitalized_name)
          end

          where(:ignorecase, :result) do
            false | [ref(:conan_package)]
            true  | [ref(:conan_package2), ref(:conan_package)]
            nil   | [ref(:conan_package2), ref(:conan_package)]
          end

          with_them do
            let(:params) { { query: "#{capitalized_name[0..3]}*", ignorecase: ignorecase } }

            it { is_expected.to match_array(result) }
          end
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

    context 'with package username and channel' do
      let(:query) { conan_package.conan_recipe }

      context 'with a valid query and user with permissions' do
        before_all do
          project.add_reporter(user)
        end

        context 'with conan_recipe as query' do
          it { is_expected.to match_array([conan_package]) }
        end

        context 'without version in query' do
          let(:query) { conan_package.conan_recipe.sub(conan_package.version, '') }

          it { is_expected.to match_array([conan_package]) }
        end
      end

      context 'with a user without permissions' do
        it { is_expected.to eq([]) }
      end

      context 'with a non-existent username and channel' do
        let(:query) do
          "#{conan_package.name}/#{conan_package.version}@#{non_existent_username}/#{non_existent_channel}"
        end

        it { is_expected.to eq([]) }
      end

      context 'with a specified project' do
        let(:query) { private_package.conan_recipe }
        let(:finder) { described_class.new(user, params, project: private_project) }

        it { is_expected.to match_array([private_package]) }

        context 'with a non-existent username and channel' do
          let(:query) do
            "#{private_package.name}/#{private_package.version}@#{non_existent_username}/#{non_existent_channel}"
          end

          it { is_expected.to eq([]) }
        end
      end
    end
  end
end
