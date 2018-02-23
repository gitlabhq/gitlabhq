require 'spec_helper'

describe IssuesFinder do
  it_behaves_like 'a finder with external authorization service' do
    let!(:subject) { create(:issue, project: project) }
    let(:project_params) { { project_id: project.id } }
  end
end
