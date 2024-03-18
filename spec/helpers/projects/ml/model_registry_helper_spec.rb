# frozen_string_literal: true

require 'rspec'

require 'spec_helper'
require 'mime/types'

RSpec.describe Projects::Ml::ModelRegistryHelper, feature_category: :mlops do
  let_it_be(:project) { build_stubbed(:project) }
  let_it_be(:user) { project.owner }

  describe '#index_ml_model_data' do
    subject(:parsed) { Gitlab::Json.parse(helper.index_ml_model_data(project, user)) }

    it 'generates the correct data' do
      is_expected.to eq({
        'projectPath' => project.full_path,
        'createModelPath' => "/#{project.full_path}/-/ml/models/new",
        'canWriteModelRegistry' => true,
        'mlflowTrackingUrl' => "http://localhost/api/v4/projects/#{project.id}/ml/mlflow/"
      })
    end

    context 'when user does not have write access to model registry' do
      before do
        allow(Ability).to receive(:allowed?).and_call_original
        allow(Ability).to receive(:allowed?)
                            .with(user, :write_model_registry, project)
                            .and_return(false)
      end

      it 'canWriteModelRegistry is false' do
        expect(parsed['canWriteModelRegistry']).to eq(false)
      end
    end
  end

  describe '#show_ml_model_data' do
    let_it_be(:model) do
      build_stubbed(:ml_models, :with_latest_version_and_package, project: project, description: "A description")
    end

    let_it_be(:experiment) { model.default_experiment.tap { |e| e.iid = 100 } }
    let_it_be(:candidate) { model.latest_version.candidate.tap { |c| c.iid = 101 } }
    let_it_be(:candidates) { Array.new(2) { build_stubbed(:ml_candidates, experiment: experiment) } }

    subject(:parsed) { Gitlab::Json.parse(helper.show_ml_model_data(model, user)) }

    before do
      allow(model).to receive(:candidates).and_return(candidates)
    end

    it 'generates the correct data' do
      is_expected.to eq({
        'projectPath' => project.full_path,
        'indexModelsPath' => "/#{project.full_path}/-/ml/models",
        'canWriteModelRegistry' => true,
        'mlflowTrackingUrl' => "http://localhost/api/v4/projects/#{project.id}/ml/mlflow/",
        'model' => {
          'id' => model.id,
          'name' => model.name,
          'path' => "/#{project.full_path}/-/ml/models/#{model.id}",
          'description' => 'A description',
          'latestVersion' => {
            'version' => model.latest_version.version,
            'description' => model.latest_version.description,
            'path' => "/#{project.full_path}/-/ml/models/#{model.id}/versions/#{model.latest_version.id}",
            'projectPath' => "/#{project.full_path}",
            'packageId' => model.latest_version.package_id,
            'candidate' => {
              'info' => {
                'iid' => candidate.iid,
                'eid' => candidate.eid,
                'pathToArtifact' => nil,
                'experimentName' => candidate.experiment.name,
                'pathToExperiment' => "/#{project.full_path}/-/ml/experiments/#{experiment.iid}",
                'status' => 'running',
                'path' => "/#{project.full_path}/-/ml/candidates/#{candidate.iid}",
                'ciJob' => nil
              },
              'metrics' => [],
              'params' => [],
              'metadata' => []
            }
          },
          'versionCount' => 1,
          'candidateCount' => 2
        }
      })
    end

    context 'when user does not have write access to model registry' do
      before do
        allow(Ability).to receive(:allowed?).and_call_original
        allow(Ability).to receive(:allowed?)
                            .with(user, :write_model_registry, project)
                            .and_return(false)
      end

      it 'canWriteModelRegistry is false' do
        expect(parsed['canWriteModelRegistry']).to eq(false)
      end
    end
  end
end
