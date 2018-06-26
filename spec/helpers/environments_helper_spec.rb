require 'spec_helper'

describe EnvironmentsHelper do
  include ApplicationHelper

  describe 'operations_metrics_path' do
    let(:project) { create(:project) }

    it 'returns empty metrics path when environment is nil' do
      expect(helper.operations_metrics_path(project, nil)).to eq(empty_project_environments_path(project))
    end

    it 'returns environment metrics path when environment is passed' do
      environment = create(:environment, project: project)

      expect(helper.operations_metrics_path(project, environment)).to eq(environment_metrics_path(environment))
    end
  end
end
