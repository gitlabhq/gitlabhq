# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::AutocompleteController, '(JavaScript fixtures)', type: :controller do
  include JavaScriptFixturesHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, name: 'frontend-fixtures') }

  let(:project) { create(:project, namespace: group, path: 'autocomplete-project') }
  let(:merge_request) { create(:merge_request, source_project: project, author: user) }

  before do
    group.add_owner(user)
    sign_in(user)
  end

  it 'autocomplete/users.json' do
    20.times do
      user = create(:user)
      project.add_developer(user)
    end

    get(
      :users,
      format: :json,
      params: {
        project_id: project.id,
        active: true,
        current_user: true,
        author: merge_request.author.id,
        merge_request_iid: merge_request.iid
      }
    )

    expect(response).to be_successful
  end
end
