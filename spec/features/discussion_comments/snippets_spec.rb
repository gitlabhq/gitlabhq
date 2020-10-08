# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Thread Comments Snippet', :js do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:snippet) { create(:project_snippet, :private, :repository, project: project, author: user) }

  before do
    project.add_maintainer(user)
    sign_in(user)

    visit project_snippet_path(project, snippet)
  end

  it_behaves_like 'thread comments', 'snippet'
end
