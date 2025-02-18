# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'GraphQL Explorer', :js, feature_category: :api do
  let_it_be(:user) { create(:user) }

  before do
    sign_in(user)
  end

  # We cache the IntrospectionQuery based on the default IntrospectionQuery by GraphiQL. If this spec fails,
  # the IntrospectionQuery has changed and we should update our cache to match.
  # It is stored in `app/graphql/cached_introspection_query.rb#query_string`
  it 'executes the expected introspection query' do
    expect(GitlabSchema).to receive(:execute).and_wrap_original do |method, query, **kwargs|
      expect(query.squish).to eq(CachedIntrospectionQuery.query_string)

      method.call(query, **kwargs)
    end

    visit '/-/graphql-explorer'

    # Working autocomplete means the introspection query was successful
    fill_in_editor('query { projec')
    expect(page).to have_css('.CodeMirror-hints', text: 'project')
  end

  it 'renders the documentation' do
    visit '/-/graphql-explorer'

    click_button('Show Documentation Explorer')

    expect(page).to have_content('Docs')
    expect(page).to have_content('A GraphQL schema provides a root type for each kind of operation.')
  end

  it 'allows user to execute a query' do
    visit '/-/graphql-explorer'

    fill_in_editor('query { currentUser { id } }')
    click_execute_button

    expect_response(%("currentUser": { "id": "#{user.to_gid}" }))
  end

  it 'allows user to execute a query with a custom header' do
    visit '/-/graphql-explorer'

    fill_in_editor('query { currentUser { id } }')
    # Test with a non-existing URL endpoint, so that we expect a 404
    fill_in_header('{ "REQUEST_PATH": "/alternative/path/graphql" }')
    click_execute_button

    expect_response(%("statusCode": 404))
  end

  it 'allows user to execute one of multiple named queries' do
    visit '/-/graphql-explorer'

    fill_in_editor(
      'query currentUserId { currentUser { ...UserIdFragment } } ' \
        'query currentUsername { currentUser { username } } ' \
        'fragment UserIdFragment on User { id }'
    )
    sleep 0.1 # GraphiQL needs to parse the query in the background before we click execute

    click_execute_button
    find('.graphiql-dropdown-item', text: 'currentUserId').click

    expect_response(%("currentUser": { "id": "#{user.to_gid}" }))
  end

  it 'allows user to execute a mutation' do
    visit '/-/graphql-explorer'

    fill_in_editor('mutation { echoCreate(input: { messages: ["hello world!"] }) { echoes } }')
    click_execute_button

    expect_response('"echoes": [ "hello world!" ]')
  end

  it 'allows user to execute a subscription' do
    work_item = create(:work_item, project: create(:project, :public))

    visit '/-/graphql-explorer'

    fill_in_editor(%(subscription { workItemUpdated(workItemId: "#{work_item.to_gid}") { title } }))
    click_execute_button

    expect_response('"workItemUpdated": null')

    work_item.update!(title: 'My new title')
    GraphqlTriggers.work_item_updated(work_item)

    expect_response('"workItemUpdated": { "title": "My new title" }')
  end

  def fill_in_editor(text)
    within '.graphiql-editor' do
      current_scope.click # focus the editor

      enter_text_in_hidden_textarea(text)
    end
  end

  def fill_in_header(header_json)
    within '.graphiql-editor-tools' do
      current_scope.find('button[data-name="headers"]').click # focus the header editor
    end

    within '.graphiql-editor-tool' do
      current_scope.click

      within '.graphiql-editor' do
        enter_text_in_hidden_textarea(header_json)
      end
    end
  end

  def click_execute_button
    find('.graphiql-execute-button').click
  end

  def expect_response(text)
    expect(page).to have_css('.graphiql-response', text: text, normalize_ws: true)
  end

  def enter_text_in_hidden_textarea(text)
    # CodeMirror uses a hidden textarea
    field = current_scope.find("textarea", visible: false)

    field.send_keys :enter
    field.send_keys text
  end
end
