# frozen_string_literal: true

require 'spec_helper'

describe SnippetsController, '(JavaScript fixtures)', type: :controller do
  include JavaScriptFixturesHelpers

  let(:admin) { create(:admin) }
  let(:namespace) { create(:namespace, name: 'frontend-fixtures' )}
  let(:project) { create(:project, :repository, namespace: namespace, path: 'branches-project') }
  let(:snippet) { create(:personal_snippet, title: 'snippet.md', content: '# snippet', file_name: 'snippet.md', author: admin) }

  render_views

  before(:all) do
    clean_frontend_fixtures('snippets/')
  end

  before do
    stub_feature_flags(snippets_vue: false)
    sign_in(admin)
    allow(Discussion).to receive(:build_discussion_id).and_return(['discussionid:ceterumcenseo'])
  end

  after do
    remove_repository(project)
  end

  it 'snippets/show.html' do
    create(:discussion_note_on_snippet, noteable: snippet, project: project, author: admin, note: '- [ ] Task List Item')

    get(:show, params: { id: snippet.to_param })

    expect(response).to be_successful
  end
end
