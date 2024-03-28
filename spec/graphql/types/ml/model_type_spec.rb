# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['MlModel'], feature_category: :mlops do
  let_it_be(:model) { create(:ml_models, :with_latest_version_and_package, description: 'A description') }
  let_it_be(:project) { model.project }
  let_it_be(:candidates) { Array.new(2) { create(:ml_candidates, experiment: model.default_experiment) } }

  let(:query) do
    %(
        query {
          mlModel(id: "gid://gitlab/Ml::Model/#{model.id}") {
            id
            description
            name
            versionCount
            candidateCount
            latestVersion {
              id
            }
            _links {
              showPath
            }
          }
        }
      )
  end

  specify { expect(described_class.description).to eq('Machine learning model in the model registry') }

  subject(:data) { GitlabSchema.execute(query, context: { current_user: project.owner }).as_json }

  it 'includes all the fields' do
    expected_fields = %w[id name versions candidates version_count _links created_at latest_version description
      candidate_count description]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end

  it 'computes the correct properties' do
    model_data = data.dig('data', 'mlModel')

    expect(model_data).to eq({
      'id' => "gid://gitlab/Ml::Model/#{model.id}",
      'name' => model.name,
      'description' => 'A description',
      'latestVersion' => {
        'id' => "gid://gitlab/Ml::ModelVersion/#{model.latest_version.id}"
      },
      'versionCount' => 1,
      'candidateCount' => 2,
      '_links' => {
        'showPath' => "/#{project.full_path}/-/ml/models/#{model.id}"
      }
    })
  end
end
