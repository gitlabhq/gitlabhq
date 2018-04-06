require 'spec_helper'

describe 'EE > Projects > Settings > User manages issue template' do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public, :repository, namespace: user.namespace) }

  before do
    sign_in(user)
    visit edit_project_path(project)
  end

  it 'saves issue template' do
    fill_in 'project_issues_template', with: "This issue should contain the following."
    page.within '.issues-feature' do
      click_button 'Save changes'
    end

    expect(find_field('project_issues_template').value).to eq 'This issue should contain the following.'
  end
end
