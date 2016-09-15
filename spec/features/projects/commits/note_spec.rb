require 'spec_helper'

describe 'Projects > Commits > Note' do
  let(:project) { create(:project) }
  let(:commit)  { project.commit('7d3b0f7cff5f37573aea97cebfd5692ea1689924') }

  before do
    login_as :user
    project.team << [@user, :master]
    visit namespace_project_commit_path(project.namespace, project, commit.id)
  end

  it 'says that only markdown is supported, not slash commands' do
    expect(page).to have_content('Styling with Markdown is supported')
  end
end
