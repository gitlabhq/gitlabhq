# frozen_string_literal: true

require 'spec_helper'

describe 'IDE user commits changes', :js do
  include WebIdeSpecHelpers

  let(:project) { create(:project, :public, :repository) }
  let(:user) { project.owner }

  before do
    sign_in(user)

    ide_visit(project)
  end

  it 'user updates nested files' do
    content = <<~HEREDOC
      Lorem ipsum
      Dolar sit
      Amit
    HEREDOC

    ide_create_new_file('foo/bar/lorem_ipsum.md', content: content)
    ide_delete_file('foo/bar/.gitkeep')

    ide_commit

    expect(page).to have_content('All changes are committed')
    expect(project.repository.blob_at('master', 'foo/bar/.gitkeep')).to be_nil
    expect(project.repository.blob_at('master', 'foo/bar/lorem_ipsum.md').data).to eql(content)
  end

  it 'user adds then deletes new file' do
    ide_create_new_file('foo/bar/lorem_ipsum.md')

    expect(page).to have_selector(ide_commit_tab_selector)

    ide_delete_file('foo/bar/lorem_ipsum.md')

    expect(page).not_to have_selector(ide_commit_tab_selector)
  end
end
