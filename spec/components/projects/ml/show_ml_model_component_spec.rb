# frozen_string_literal: true

require "spec_helper"

RSpec.describe Projects::Ml::ShowMlModelComponent, type: :component, feature_category: :mlops do
  # rubocop:disable RSpec/FactoryBot/AvoidCreate -- build_stubbed breaks because it doesn't create iids properly.
  let_it_be(:project) { create(:project) }
  let_it_be(:model1) do
    create(:ml_models, :with_latest_version_and_package, project: project, description: "A description")
  end
  # rubocop:enable RSpec/FactoryBot/AvoidCreate

  let_it_be(:experiment) { model1.default_experiment }
  let_it_be(:candidate) { model1.latest_version.candidate }

  subject(:component) do
    described_class.new(model: model1, current_user: model1.user)
  end

  describe 'rendered' do
    before do
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
          'versionCount' => 1
        }
      })
    end
  end
end
