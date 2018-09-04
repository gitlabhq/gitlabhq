require 'rails_helper'

describe 'New merge request breadcrumbs' do
  let(:project) { create(:project) }
  let(:user)    { project.creator }

  before do
    sign_in(user)
    visit project_new_merge_request_path(project)
  end

  it 'display a link to project merge requests and new merge request pages' do
    page.within '.breadcrumbs' do
      expect(find_link('Merge Requests')[:href]).to end_with(project_merge_requests_path(project))
      expect(find_link('New')[:href]).to end_with(project_new_merge_request_path(project))
    end
  end
end
