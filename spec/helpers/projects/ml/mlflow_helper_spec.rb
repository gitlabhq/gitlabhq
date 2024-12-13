# frozen_string_literal: true

require 'rspec'

require 'spec_helper'
require 'mime/types'

RSpec.describe Projects::Ml::MlflowHelper, feature_category: :mlops do
  let_it_be(:project) { build_stubbed(:project) }

  describe '#mlflow_tracking_url' do
    it 'generates the correct data' do
      expect(helper.mlflow_tracking_url(project)).to eq("http://localhost/api/v4/projects/#{project.id}/ml/mlflow/")
    end
  end
end
