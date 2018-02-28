require 'spec_helper'

describe TodosFinder do
  it_behaves_like 'a finder with external authorization service' do
    let!(:subject) { create(:todo, project: project, user: user) }
    let(:project_params) { { project_id: project.id } }
  end
end
