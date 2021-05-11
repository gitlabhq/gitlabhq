# frozen_string_literal: true
require 'spec_helper'

RSpec.describe ::Packages::Conan::PackageFinder do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }

  describe '#execute' do
    let!(:conan_package) { create(:conan_package, project: project) }
    let!(:conan_package2) { create(:conan_package, project: project) }

    subject { described_class.new(user, query: query).execute }

    context 'packages that are not installable' do
      let!(:conan_package3) { create(:conan_package, :error, project: project) }
      let!(:non_visible_project) { create(:project, :private) }
      let!(:non_visible_conan_package) { create(:conan_package, project: non_visible_project) }
      let(:query) { "#{conan_package.name.split('/').first[0, 3]}%" }

      it { is_expected.to eq [conan_package, conan_package2] }
    end
  end
end
