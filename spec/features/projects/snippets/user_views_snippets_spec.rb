require 'spec_helper'

describe 'User views snippets' do
  let(:project) { create(:project) }
  let!(:project_snippet) { create(:project_snippet, project: project, author: user) }
  let!(:snippet) { create(:snippet, author: user) }
  let(:user) { create(:user) }

  before do
    project.add_master(user)
    sign_in(user)

    visit(project_snippets_path(project))
  end

  it 'shows snippets' do
    expect(page).to have_content(project_snippet.title)
    expect(page).not_to have_content(snippet.title)
  end
end
