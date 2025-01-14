# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['MlCandidate'], feature_category: :mlops do
  let_it_be(:model_version) { create(:ml_model_versions, :with_package) }
  let_it_be(:project) { model_version.project }
  let_it_be(:current_user) { project.owner }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project, user: current_user) }
  let_it_be(:candidate) do
    model_version.candidate.tap do |c|
      c.update!(ci_build: create(:ci_build, pipeline: pipeline, user: current_user))
      c.metrics = [create(:ml_candidate_metrics, candidate: c)]
      c.params = [create(:ml_candidate_params, candidate: c)]
      c.metadata = [create(:ml_candidate_metadata, candidate: c)]
    end
  end

  let(:query) do
    %(
        query {
          mlModel(id: "gid://gitlab/Ml::Model/#{model_version.model.id}") {
            id
            latestVersion {
              id
              candidate {
                id
                name
                iid
                eid
                status
                creator {
                  id
                  name
                  webUrl
                }
                ciJob {
                  id
                }
                _links {
                  showPath
                  artifactPath
                }
                metrics {
                  nodes {
                    id
                  }
                }
                params {
                  nodes {
                    id
                  }
                }
                metadata {
                  nodes {
                    id
                  }
                }
              }
            }
          }
        }
      )
  end

  specify { expect(described_class.description).to eq('Candidate for a model version in the model registry') }

  subject(:data) { GitlabSchema.execute(query, context: { current_user: project.owner }).as_json }

  it 'computes the correct properties' do
    candidate_data = data.dig('data', 'mlModel', 'latestVersion', 'candidate')

    expect(candidate_data).to eq({
      'id' => "gid://gitlab/Ml::Candidate/#{candidate.id}",
      'name' => candidate.name,
      'iid' => candidate.iid,
      'eid' => candidate.eid,
      'status' => candidate.status,
      'creator' => {
        'id' => "gid://gitlab/User/#{current_user.id}",
        'name' => current_user.name,
        'webUrl' => "http://localhost/#{current_user.username}"
      },
      'ciJob' => {
        'id' => "gid://gitlab/Ci::Build/#{candidate.ci_build_id}"
      },
      '_links' => {
        'showPath' => "/#{project.full_path}/-/ml/candidates/#{model_version.candidate.iid}",
        'artifactPath' => "/#{project.full_path}/-/packages/#{model_version.package_id}"
      },
      'metrics' => {
        'nodes' => [
          {
            'id' => "gid://gitlab/Ml::CandidateMetric/#{candidate.metrics.first.id}"
          }
        ]
      },
      'params' => {
        'nodes' => [
          {
            'id' => "gid://gitlab/Ml::CandidateParam/#{candidate.params.first.id}"
          }
        ]
      },
      'metadata' => {
        'nodes' => [
          {
            'id' => "gid://gitlab/Ml::CandidateMetadata/#{candidate.metadata.first.id}"
          }
        ]
      }
    })
  end
end
