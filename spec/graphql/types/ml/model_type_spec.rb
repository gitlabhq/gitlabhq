# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['MlModel'], feature_category: :mlops do
  let_it_be(:model) { create(:ml_models, :with_latest_version_and_package, description: 'A description') }
  let_it_be(:model_markdown) { create(:ml_models, :with_latest_version_and_package, description: 'A **description**') }
  let_it_be(:project) { model.project }
  let_it_be(:project_markdown) { model_markdown.project }
  let_it_be(:candidates) { Array.new(2) { create(:ml_candidates, experiment: model.default_experiment) } }
  let_it_be(:candidates_markdown) do
    Array.new(2) do
      create(:ml_candidates, experiment: model_markdown.default_experiment)
    end
  end

  let_it_be(:model_id) { GitlabSchema.id_from_object(model).to_s }
  let_it_be(:model_version_id) { GitlabSchema.id_from_object(model.latest_version).to_s }

  let_it_be(:model_id_markdown) { GitlabSchema.id_from_object(model_markdown).to_s }
  let_it_be(:model_version_id_markdown) { GitlabSchema.id_from_object(model_markdown.latest_version).to_s }

  let(:query) do
    %(
        query {
          mlModel(id: "#{model_id}") {
            id
            createdAt
            author {
              id
              username
              webUrl
              avatarUrl
            }
            description
            descriptionHtml
            defaultExperimentPath
            name
            versionCount
            candidateCount
            latestVersion {
              id
            }
            version(modelVersionId: "#{model_version_id}") {
              id
            }
            _links {
              showPath
            }
          }
        }
      )
  end

  let(:query_markdown) do
    %(
        query {
          mlModel(id: "#{model_id_markdown}") {
            id
            createdAt
            author {
              id
              username
              webUrl
              avatarUrl
            }
            description
            descriptionHtml
            defaultExperimentPath
            name
            versionCount
            candidateCount
            latestVersion {
              id
            }
            version(modelVersionId: "#{model_version_id_markdown}") {
              id
            }
            _links {
              showPath
            }
          }
        }
      )
  end

  let(:data) { GitlabSchema.execute(query, context: { current_user: project.owner }).as_json }

  specify { expect(described_class.description).to eq('Machine learning model in the model registry') }

  subject(:data_markdown) do
    GitlabSchema.execute(query_markdown, context: { current_user: project_markdown.owner }).as_json
  end

  it 'includes all the fields' do
    expected_fields = %w[id name versions candidates version_count _links created_at latest_version description
      candidate_count description version description_html author]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end

  it 'computes the correct properties' do
    model_data = data.dig('data', 'mlModel')
    user = model.user
    expect(model_data).to eq({
      'id' => model_id,
      'name' => model.name,
      'createdAt' => model.created_at.iso8601(0),
      'author' => {
        'id' => user.to_global_id.to_s,
        'username' => user.username,
        'webUrl' => "http://localhost/#{user.username}",
        'avatarUrl' => user.avatar_url
      },
      'description' => 'A description',
      'descriptionHtml' =>
        '<p data-sourcepos="1:1-1:13" dir="auto">A description</p>',
      'defaultExperimentPath' =>
        "/#{project.full_path}/-/ml/experiments/#{model.default_experiment.iid}",
      'latestVersion' => {
        'id' => model_version_id
      },
      'version' => {
        'id' => model_version_id
      },
      'versionCount' => 1,
      'candidateCount' => 2,
      '_links' => {
        'showPath' => "/#{project.full_path}/-/ml/models/#{model.id}"
      }
    })
  end

  it 'computes the correct properties with markdown' do
    model_data = data_markdown.dig('data', 'mlModel')
    user = model_markdown.user
    expect(model_data).to eq({
      'id' => model_id_markdown,
      'name' => model_markdown.name,
      'createdAt' => model_markdown.created_at.iso8601(0),
      'author' => {
        'id' => user.to_global_id.to_s,
        'username' => user.username,
        'webUrl' => "http://localhost/#{user.username}",
        'avatarUrl' => user.avatar_url
      },
      'description' => model_markdown.description,
      'descriptionHtml' =>
        '<p data-sourcepos="1:1-1:17" dir="auto">A <strong data-sourcepos="1:3-1:17">description</strong></p>',
      'defaultExperimentPath' =>
        "/#{project_markdown.full_path}/-/ml/experiments/#{model_markdown.default_experiment.iid}",
      'latestVersion' => {
        'id' => model_version_id_markdown
      },
      'version' => {
        'id' => model_version_id_markdown
      },
      'versionCount' => 1,
      'candidateCount' => 2,
      '_links' => {
        'showPath' => "/#{project_markdown.full_path}/-/ml/models/#{model_markdown.id}"
      }
    })
  end
end
