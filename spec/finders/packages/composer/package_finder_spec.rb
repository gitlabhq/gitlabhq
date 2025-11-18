# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Packages::Composer::PackageFinder, feature_category: :package_registry do
  describe '#execute' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, namespace: group) }
    let_it_be(:target_sha) { OpenSSL::Digest.hexdigest('SHA1', FFaker::Lorem.word) }
    let_it_be(:package_sti) { create(:composer_package_sti, :with_metadatum, project: project) }
    let_it_be(:package) { ::Packages::Composer::Package.find(package_sti.id) }

    let_it_be(:package3_sti) do
      create(:composer_package_sti, :with_metadatum, project: project, sha: target_sha, name: package.name)
    end

    let_it_be(:package3) { ::Packages::Composer::Package.find(package3_sti.id) }

    let(:project_or_group) { project }
    let(:params) { {} }

    before_all do
      create(:composer_package_sti, :with_metadatum)
    end

    subject(:result) { described_class.new(user, project_or_group, params).execute }

    shared_examples 'filtering by parameters' do
      context 'when parameters are provided' do
        let(:params) { { package_name: package.name, target_sha: target_sha } }

        it { is_expected.to contain_exactly(package3) }
      end
    end

    it { is_expected.to contain_exactly(package, package3) }

    it_behaves_like 'filtering by parameters'

    context 'when group is provided' do
      let(:project_or_group) { group }

      it { is_expected.to be_empty }

      context 'when user has permissions' do
        before_all do
          group.add_reporter(user)
        end

        it { is_expected.to contain_exactly(package, package3) }

        it_behaves_like 'filtering by parameters'
      end
    end
  end
end
