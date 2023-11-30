# frozen_string_literal: true

require "spec_helper"

RSpec.describe Projects::Ml::ShowMlModelComponent, type: :component, feature_category: :mlops do
  let_it_be(:project) { build_stubbed(:project) }
  let_it_be(:model1) { build_stubbed(:ml_models, :with_latest_version_and_package, project: project) }

  subject(:component) do
    described_class.new(model: model1)
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
          'description' => 'This is a placeholder for the short description',
          'latestVersion' => {
            'version' => model1.latest_version.version,
            'description' => model1.latest_version.description,
            'projectPath' => "/#{project.full_path}",
            'packageId' => model1.latest_version.package_id
          },
          'versionCount' => 1
        }
      })
    end
  end
end
