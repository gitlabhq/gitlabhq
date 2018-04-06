require 'spec_helper'

describe 'EE > Projects > Settings > User manages merge requests template' do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public, :repository, namespace: user.namespace) }

  before do
    sign_in(user)
    visit edit_project_path(project)
  end

  it 'saves merge request template' do
    fill_in 'project_merge_requests_template', with: "This merge request should contain the following."
    page.within '.merge-requests-feature' do
      click_button 'Save changes'
    end

    expect(find_field('project_merge_requests_template').value).to eq 'This merge request should contain the following.'
  end
end
