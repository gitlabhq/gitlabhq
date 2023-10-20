# frozen_string_literal: true

require "spec_helper"

RSpec.describe Projects::Ml::ShowMlModelVersionComponent, type: :component, feature_category: :mlops do
  let_it_be(:project) { build_stubbed(:project) }
  let_it_be(:model) { build_stubbed(:ml_models, project: project) }
  let_it_be(:version) { build_stubbed(:ml_model_versions, model: model) }

  subject(:component) do
    described_class.new(model_version: version)
  end

  describe 'rendered' do
    before do
      render_inline component
    end

    it 'renders element with view_model' do
      element = page.find("#js-mount-show-ml-model-version")

      expect(Gitlab::Json.parse(element['data-view-model'])).to eq({
        'modelVersion' => {
          'id' => version.id,
          'version' => version.version,
          'path' => "/#{project.full_path}/-/ml/models/#{model.id}/versions/#{version.id}",
          'model' => {
            'name' => model.name,
            'path' => "/#{project.full_path}/-/ml/models/#{model.id}"
          }
        }
      })
    end
  end
end
