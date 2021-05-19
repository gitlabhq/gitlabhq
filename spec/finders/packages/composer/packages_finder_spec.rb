# frozen_string_literal: true
require 'spec_helper'

RSpec.describe ::Packages::Composer::PackagesFinder do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }

  let(:params) { {} }

  describe '#execute' do
    let_it_be(:composer_package) { create(:composer_package, project: project) }
    let_it_be(:composer_package2) { create(:composer_package, project: project) }
    let_it_be(:error_package) { create(:composer_package, :error, project: project) }
    let_it_be(:composer_package3) { create(:composer_package) }

    subject { described_class.new(user, group, params).execute }

    before do
      project.add_developer(user)
    end

    it { is_expected.to match_array([composer_package, composer_package2]) }
  end
end
