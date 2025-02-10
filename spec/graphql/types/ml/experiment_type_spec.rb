# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['MlExperiment'], feature_category: :mlops do
  let(:experiment) { create(:ml_experiments, :with_candidates, :with_model) }
  let(:project) { experiment.project }
  let(:experiment_id) { GitlabSchema.id_from_object(experiment).to_s }

  let(:query) do
    %(
      query {
        mlExperiment(id: "#{experiment_id}") {
          id
          name
          createdAt
          updatedAt
          path
          candidateCount
          creator {
            id
            name
            webUrl
          }
          modelId
          candidates {
            nodes {
              id
              name
            }
          }
        }
      }
    )
  end

  let(:data) { GitlabSchema.execute(query, context: { current_user: project.owner }).as_json }

  specify { expect(described_class.description).to eq('Machine learning experiment in model experiments') }

  it 'includes all the fields' do
    expected_fields = %w[id name createdAt updatedAt path candidateCount creator modelId candidates]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end

  context 'when experiment has model and candidates' do
    it 'computes the correct properties' do
      experiment_data = data.dig('data', 'mlExperiment')
      expect(experiment_data).to eq({
        'id' => experiment_id,
        'name' => experiment.name,
        'createdAt' => experiment.created_at.iso8601(0),
        'updatedAt' => experiment.updated_at.iso8601(0),
        'candidateCount' => experiment.candidates.count,
        'path' => "/#{project.path_with_namespace}/-/ml/experiments/#{experiment.iid}",
        'creator' => {
          'id' => project.owner.to_global_id.to_s,
          'name' => project.owner.name,
          'webUrl' => "http://localhost/#{project.owner.username}"
        },
        'modelId' => experiment.model.to_global_id.to_s,
        'candidates' => {
          'nodes' => experiment.candidates.sort_by(&:id).reverse.map do |candidate|
            {
              'id' => GitlabSchema.id_from_object(candidate).to_s,
              'name' => candidate.name
            }
          end
        }
      })
    end
  end

  context 'when experiment has no model or candidates' do
    let(:experiment) { create(:ml_experiments) }

    it 'computes the correct properties' do
      experiment_data = data.dig('data', 'mlExperiment')
      expect(experiment_data).to eq({
        'id' => experiment_id,
        'name' => experiment.name,
        'createdAt' => experiment.created_at.iso8601(0),
        'updatedAt' => experiment.updated_at.iso8601(0),
        'candidateCount' => experiment.candidates.count,
        'path' => "/#{project.path_with_namespace}/-/ml/experiments/#{experiment.iid}",
        'creator' => {
          'id' => project.owner.to_global_id.to_s,
          'name' => project.owner.name,
          'webUrl' => "http://localhost/#{project.owner.username}"
        },
        'modelId' => nil,
        'candidates' => {
          'nodes' => []
        }
      })
    end
  end

  context 'when experiment has candidates but no model' do
    let(:experiment) { create(:ml_experiments, :with_candidates) }

    it 'computes the correct properties' do
      experiment_data = data.dig('data', 'mlExperiment')
      expect(experiment_data).to eq({
        'id' => experiment_id,
        'name' => experiment.name,
        'createdAt' => experiment.created_at.iso8601(0),
        'updatedAt' => experiment.updated_at.iso8601(0),
        'candidateCount' => experiment.candidates.count,
        'path' => "/#{project.path_with_namespace}/-/ml/experiments/#{experiment.iid}",
        'creator' => {
          'id' => project.owner.to_global_id.to_s,
          'name' => project.owner.name,
          'webUrl' => "http://localhost/#{project.owner.username}"
        },
        'modelId' => nil,
        'candidates' => {
          'nodes' => experiment.candidates.sort_by(&:id).reverse.map do |candidate|
            {
              'id' => GitlabSchema.id_from_object(candidate).to_s,
              'name' => candidate.name
            }
          end
        }
      })
    end
  end
end
