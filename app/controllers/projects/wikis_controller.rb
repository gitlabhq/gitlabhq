# frozen_string_literal: true

class Projects::WikisController < Projects::ApplicationController
  include WikiActions
  include PreviewMarkdown

  alias_method :container, :project

  def git_access
  end
end
