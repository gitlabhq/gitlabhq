require 'spec_helper'

describe MergeRequestsFinder do
  it_behaves_like 'a finder with external authorization service' do
    let!(:subject) { create(:merge_request, source_project: project) }
    let(:project_params) { { project_id: project.id } }
  end
end
