# frozen_string_literal: true

require "spec_helper"

RSpec.describe Projects::Ml::ModelsIndexComponent, type: :component, feature_category: :mlops do
  let_it_be(:project) { build_stubbed(:project) }
  let_it_be(:user) { project.owner }
  let_it_be(:model1) { build_stubbed(:ml_models, :with_latest_version_and_package, project: project) }
  let_it_be(:model2) { build_stubbed(:ml_models, project: project) }
  let_it_be(:models) { [model1, model2] }

  let(:paginator) do
    Class.new do
      def initialize(models:)
        @models = models
      end

      def records = @models
      def has_next_page? = true
      def has_previous_page? = false
      def cursor_for_previous_page = 'abcde'
      def cursor_for_next_page = 'defgh'
    end.new(models: models)
  end

  subject(:component) do
    described_class.new(project: project, current_user: user, model_count: 5, paginator: paginator)
  end

  describe 'rendered' do
    let(:element) { page.find("#js-index-ml-models") }

    context 'when user can write model registry' do
      before do
        allow(model1).to receive(:version_count).and_return(1)
        allow(model2).to receive(:version_count).and_return(0)
        render_inline component
      end

      it 'renders element with view_model' do
        expect(Gitlab::Json.parse(element['data-view-model'])).to eq({
          'models' => [
            {
              'name' => model1.name,
              'version' => model1.latest_version.version,
              'path' => "/#{project.full_path}/-/ml/models/#{model1.id}",
              'versionPackagePath' => "/#{project.full_path}/-/packages/#{model1.latest_version.package_id}",
              'versionPath' => "/#{project.full_path}/-/ml/models/#{model1.id}/versions/#{model1.latest_version.id}",
              'versionCount' => 1
            },
            {
              'name' => model2.name,
              'path' => "/#{project.full_path}/-/ml/models/#{model2.id}",
              'version' => nil,
              'versionPackagePath' => nil,
              'versionPath' => nil,
              'versionCount' => 0
            }
          ],
          'pageInfo' => {
            'hasNextPage' => true,
            'hasPreviousPage' => false,
            'startCursor' => 'abcde',
            'endCursor' => 'defgh'
          },
          'modelCount' => 5,
          'createModelPath' => "/#{project.full_path}/-/ml/models/new",
          'canWriteModelRegistry' => true,
          'mlflowTrackingUrl' => "http://localhost/api/v4/projects/#{project.id}/ml/mlflow/api/2.0/mlflow/"
        })
      end
    end

    context 'when user cannot write model registry' do
      before do
        allow(Ability).to receive(:allowed?).and_call_original
        allow(Ability).to receive(:allowed?)
                            .with(user, :write_model_registry, project)
                            .and_return(false)

        render_inline component
      end

      it 'canWriteModelRegistry is false' do
        expect(Gitlab::Json.parse(element['data-view-model'])['canWriteModelRegistry']).to eq(false)
      end
    end
  end
end
