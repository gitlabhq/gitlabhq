# frozen_string_literal: true

class Snippets::ApplicationController < ApplicationController
  include FindSnippet
  include SnippetAuthorizations

  feature_category :source_code_management

  private

  def authorize_read_snippet!
    return if can?(current_user, :read_snippet, snippet)

    if current_user
      render_404
    else
      authenticate_user!
    end
  end

  def snippet_klass
    PersonalSnippet
  end
end
