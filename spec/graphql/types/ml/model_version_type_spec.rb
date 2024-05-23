# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['MlModelVersion'], feature_category: :mlops do
  let_it_be(:model_version) { create(:ml_model_versions, :with_package, description: 'A description') }
  let_it_be(:project) { model_version.project }
  let_it_be(:current_user) { project.owner }

  let(:query) do
    %(
    query {
          mlModel(id: "gid://gitlab/Ml::Model/#{model_version.model.id}") {
            id
            latestVersion {
              id
              version
              packageId
              description
              candidate {
                id
              }
              _links {
                packagePath
                showPath
                importPath
              }
            }
          }
        }
      )
  end

  specify { expect(described_class.description).to eq('Version of a machine learning model') }

  subject(:data) { GitlabSchema.execute(query, context: { current_user: project.owner }).as_json }

  it 'includes all fields' do
    expected_fields = %w[id version created_at _links candidate package_id description]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end

  it 'computes the correct properties' do
    version_data = data.dig('data', 'mlModel', 'latestVersion')

    expect(version_data).to eq({
      'id' => "gid://gitlab/Ml::ModelVersion/#{model_version.id}",
      'version' => model_version.version,
      'description' => 'A description',
      'packageId' => "gid://gitlab/Packages::Package/#{model_version.package_id}",
      'candidate' => {
        'id' => "gid://gitlab/Ml::Candidate/#{model_version.candidate.id}"
      },
      '_links' => {
        'showPath' => "/#{project.full_path}/-/ml/models/#{model_version.model.id}/versions/#{model_version.id}",
        'packagePath' => "/#{project.full_path}/-/packages/#{model_version.package_id}",
        'importPath' => "/api/v4/projects/#{project.id}/packages/ml_models/#{model_version.id}/files/"
      }
    })
  end
end
