# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::Catalog::Resources::VersionType, feature_category: :pipeline_composition do
  include GraphqlHelpers

  specify { expect(described_class.graphql_name).to eq('CiCatalogResourceVersion') }

  it 'exposes the expected fields' do
    expected_fields = %i[
      author
      commit
      components
      created_at
      id
      name
      path
      readme
      readme_html
      released_at
      semver
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  describe '#readme' do
    let_it_be(:project) { create(:project, :public, :custom_repo, files: { 'README.md' => '**Test**' }) }
    let_it_be(:resource) { create(:ci_catalog_resource, :published, project: project) }
    let_it_be(:version) { create(:ci_catalog_resource_version, catalog_resource: resource) }
    let_it_be(:user) { create(:user) }

    before do
      allow(version).to receive(:readme).and_return('# Test README')
    end

    context 'when user has read_code permission' do
      it 'resolves the readme field' do
        result = resolve_field(:readme, version, current_user: user)

        expect(result).to eq('# Test README')
      end
    end

    context 'when user does not have read_code permission' do
      before do
        project.project_feature.update!(
          repository_access_level: ProjectFeature::DISABLED,
          merge_requests_access_level: ProjectFeature::DISABLED,
          builds_access_level: ProjectFeature::DISABLED
        )
      end

      it 'returns nil' do
        result = resolve_field(:readme, version, current_user: user)

        expect(result).to be_nil
      end
    end
  end
end
