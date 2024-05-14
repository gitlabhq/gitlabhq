# frozen_string_literal: true

class Projects::Snippets::ApplicationController < Projects::ApplicationController
  include FindSnippet
  include SnippetAuthorizations

  feature_category :source_code_management

  private

  # This overrides the default snippet create authorization
  # because ProjectSnippets are checked against the project rather
  # than the user
  def authorize_create_snippet!
    render_404 unless can?(current_user, :create_snippet, project)
  end

  def snippet_klass
    ProjectSnippet
  end
end
