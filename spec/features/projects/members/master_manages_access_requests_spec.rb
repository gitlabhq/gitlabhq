require 'spec_helper'

feature 'Projects > Members > Master manages access requests' do
  it_behaves_like 'Master manages access requests' do
    let(:entity) { create(:project, :public, :access_requestable) }
    let(:members_page_path) { project_project_members_path(entity) }
  end
end
