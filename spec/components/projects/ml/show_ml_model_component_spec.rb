# frozen_string_literal: true

require "spec_helper"

RSpec.describe Projects::Ml::ShowMlModelComponent, type: :component, feature_category: :mlops do
  let_it_be(:project) { build_stubbed(:project) }
  let_it_be(:model1) do
    build_stubbed(:ml_models, :with_latest_version_and_package, project: project, description: "A description")
  end

  let_it_be(:experiment) { model1.default_experiment.tap { |e| e.iid = 100 } }
  let_it_be(:candidate) { model1.latest_version.candidate.tap { |c| c.iid = 101 } }
  let_it_be(:candidates) { Array.new(2) { build_stubbed(:ml_candidates, experiment: experiment) } }

  subject(:component) do
    described_class.new(model: model1, current_user: model1.user)
  end

  describe 'rendered' do
    before do
      allow(model1).to receive(:candidates).and_return(candidates)

      render_inline component
    end

    it 'renders element with view_model' do
      element = page.find("#js-mount-show-ml-model")

      expect(Gitlab::Json.parse(element['data-view-model'])).to eq({
        'model' => {
          'id' => model1.id,
          'name' => model1.name,
          'path' => "/#{project.full_path}/-/ml/models/#{model1.id}",
          'description' => 'A description',
          'latestVersion' => {
            'version' => model1.latest_version.version,
            'description' => model1.latest_version.description,
            'path' => "/#{project.full_path}/-/ml/models/#{model1.id}/versions/#{model1.latest_version.id}",
            'projectPath' => "/#{project.full_path}",
            'packageId' => model1.latest_version.package_id,
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
  end
end
