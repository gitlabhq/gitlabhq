# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Ci::Catalog::Resources::VersionsResolver, feature_category: :pipeline_composition do
  include GraphqlHelpers

  let(:name) { nil }
  let(:search) { nil }
  let(:args) { { name: name, search: search }.compact }

  let_it_be(:current_user) { create(:user) }
  let(:ctx) { { current_user: current_user } }

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:resource) { create(:ci_catalog_resource, :published, project: project) }
  let_it_be(:release_v1) { create(:release, project: project, tag: '1.0.0') }
  let_it_be(:release_v2) { create(:release, project: project, tag: '2.0.0') }
  let_it_be(:release_v2_beta) { create(:release, project: project, tag: '2.0.0-beta') }
  let_it_be(:version_v1) do
    create(:ci_catalog_resource_version, catalog_resource: resource, release: release_v1, semver: '1.0.0')
  end

  let_it_be(:version_v2) do
    create(:ci_catalog_resource_version, catalog_resource: resource, release: release_v2, semver: '2.0.0')
  end

  let_it_be(:version_v2_beta) do
    create(:ci_catalog_resource_version, catalog_resource: resource, release: release_v2_beta, semver: '2.0.0-beta')
  end

  subject(:result) { resolve(described_class, ctx: ctx, obj: resource, args: args) }

  describe '#resolve' do
    context 'when the user is authorized to read project releases' do
      before_all do
        resource.project.add_guest(current_user)
      end

      context 'when name argument is provided' do
        let(:name) { '1.0.0' }

        it 'returns the version that matches the name' do
          expect(result.items).to contain_exactly(version_v1)
        end
      end

      context 'when search argument is provided' do
        context 'when the search term matches a single version' do
          let(:search) { '1.0.' }

          it 'returns only the matching version' do
            expect(result.items).to contain_exactly(version_v1)
          end
        end

        context 'when the search term matches multiple versions' do
          let(:search) { '2.0.' }

          it 'returns all matching versions' do
            expect(result.items).to contain_exactly(version_v2, version_v2_beta)
          end
        end

        context 'when the search term matches a prerelease version by suffix' do
          let(:search) { 'beta' }

          it 'returns the matching prerelease version' do
            expect(result.items).to contain_exactly(version_v2_beta)
          end
        end

        context 'when the search term does not match any version' do
          let(:search) { '9.9.9' }

          it 'returns an empty result' do
            expect(result.items).to be_empty
          end
        end
      end
    end
  end
end
