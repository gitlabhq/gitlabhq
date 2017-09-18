require 'spec_helper'

describe 'User deletes a snippet' do
  let(:project) { create(:project) }
  let!(:snippet) { create(:project_snippet, project: project, author: user) }
  let(:user) { create(:user) }

  before do
    project.add_master(user)
    sign_in(user)

    visit(project_snippet_path(project, snippet))
  end

  it 'deletes a snippet' do
    first(:link, 'Delete').click

    expect(page).not_to have_content(snippet.title)
  end
end
