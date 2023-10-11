# frozen_string_literal: true

require "spec_helper"

RSpec.describe Projects::Ml::ModelsIndexComponent, type: :component, feature_category: :mlops do
  let_it_be(:project) { build_stubbed(:project) }
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
    described_class.new(paginator: paginator)
  end

  describe 'rendered' do
    let(:element) { page.find("#js-index-ml-models") }

    before do
      render_inline component
    end

    it 'renders element with view_model' do
      element = page.find("#js-index-ml-models")

      expect(Gitlab::Json.parse(element['data-view-model'])).to eq({
        'models' => [
          {
            'name' => model1.name,
            'version' => model1.latest_version.version,
            'path' => "/#{project.full_path}/-/packages/#{model1.latest_version.package_id}"
          },
          {
            'name' => model2.name,
            'version' => nil,
            'path' => nil
          }
        ],
        'pageInfo' => {
          'hasNextPage' => true,
          'hasPreviousPage' => false,
          'startCursor' => 'abcde',
          'endCursor' => 'defgh'
        }
      })
    end
  end
end
