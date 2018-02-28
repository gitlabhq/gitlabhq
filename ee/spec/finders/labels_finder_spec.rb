require 'spec_helper'

describe LabelsFinder do
  it_behaves_like 'a finder with external authorization service' do
    let!(:subject) { create(:label, project: project) }
    let(:project_params) { { project_id: project.id } }
  end
end
