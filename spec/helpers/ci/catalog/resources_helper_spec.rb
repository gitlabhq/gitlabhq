# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Catalog::ResourcesHelper, feature_category: :pipeline_composition do
  include Devise::Test::ControllerHelpers

  let_it_be(:project) { build(:project) }

  describe '#can_view_namespace_catalog?' do
    subject { helper.can_view_namespace_catalog?(project) }

    before do
      stub_licensed_features(ci_namespace_catalog: false)
    end

    it 'user cannot view the Catalog in CE regardless of permissions' do
      expect(subject).to be false
    end
  end

  describe '#js_ci_catalog_data' do
    let(:project) { build(:project, :repository) }

    let(:default_helper_data) do
      {}
    end

    subject(:catalog_data) { helper.js_ci_catalog_data(project) }

    it 'returns catalog data' do
      expect(catalog_data).to eq(default_helper_data)
    end
  end
end
