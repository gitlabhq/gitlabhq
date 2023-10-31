# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SnippetsController, '(JavaScript fixtures)', type: :controller do
  include JavaScriptFixturesHelpers

  let(:user) { create(:user) }
  let(:namespace) { create(:namespace, name: 'frontend-fixtures', owner: user) }
  let(:project) { create(:project, :repository, namespace: namespace, path: 'branches-project') }
  let(:snippet) { create(:personal_snippet, :public, title: 'snippet.md', content: '# snippet', file_name: 'snippet.md', author: user) }

  render_views

  before do
    sign_in(user)
    allow(Discussion).to receive(:build_discussion_id).and_return(['discussionid:ceterumcenseo'])
  end

  after do
    remove_repository(project)
  end

  it 'snippets/show.html' do
    create(:discussion_note_on_project_snippet, noteable: snippet, project: project, author: user, note: '- [ ] Task List Item')

    get(:show, params: { id: snippet.to_param })

    expect(response).to be_successful
  end
end
