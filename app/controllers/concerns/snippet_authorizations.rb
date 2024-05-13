# frozen_string_literal: true

module SnippetAuthorizations
  extend ActiveSupport::Concern

  private

  def authorize_read_snippet!
    render_404 unless can?(current_user, :read_snippet, snippet)
  end

  def authorize_update_snippet!
    render_404 unless can?(current_user, :update_snippet, snippet)
  end

  def authorize_admin_snippet!
    render_404 unless can?(current_user, :admin_snippet, snippet)
  end

  def authorize_create_snippet!
    render_404 unless can?(current_user, :create_snippet)
  end
end
