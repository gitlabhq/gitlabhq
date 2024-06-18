# frozen_string_literal: true
require 'spec_helper'

RSpec.describe ::Packages::Composer::PackagesFinder, feature_category: :package_registry do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }

  let(:params) { { packages_class: ::Packages::Composer::Package } }

  describe '#execute' do
    let_it_be(:composer_package) { create(:composer_package, project: project) }
    let_it_be(:composer_package2) { create(:composer_package, project: project) }
    let_it_be(:error_package) { create(:composer_package, :error, project: project) }
    let_it_be(:composer_package3) { create(:composer_package) }
    let_it_be(:nuget_package) { create(:nuget_package, project: project) }

    subject { described_class.new(user, group, params).execute }

    before do
      project.add_developer(user)
    end

    it { is_expected.to match_array([composer_package, composer_package2]) }

    context 'when disabling the package registry for the project' do
      let(:params) { super().merge(with_package_registry_enabled: true) }

      before do
        project.update!(package_registry_access_level: 'disabled', packages_enabled: false)
      end

      it { is_expected.to be_empty }
    end
  end
end
