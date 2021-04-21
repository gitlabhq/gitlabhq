# frozen_string_literal: true

class Projects::SnippetsController < Projects::Snippets::ApplicationController
  include SnippetsActions
  include ToggleAwardEmoji
  include SpammableActions

  before_action :check_snippets_available!

  before_action :snippet, only: [:show, :edit, :raw, :toggle_award_emoji, :mark_as_spam]

  before_action :authorize_create_snippet!, only: :new
  before_action :authorize_read_snippet!, except: [:new, :index]
  before_action :authorize_update_snippet!, only: :edit

  before_action only: [:show] do
    push_frontend_feature_flag(:improved_emoji_picker, @project, default_enabled: :yaml)
  end

  def index
    @snippet_counts = ::Snippets::CountService
      .new(current_user, project: @project)
      .execute

    @snippets = SnippetsFinder.new(current_user, project: @project, scope: params[:scope], sort: sort_param)
      .execute
      .page(params[:page])
      .inc_author
      .inc_statistics

    return if redirect_out_of_range(@snippets)

    @noteable_meta_data = noteable_meta_data(@snippets, 'Snippet')
  end

  def new
    @snippet = @noteable = @project.snippets.build
  end

  protected

  alias_method :awardable, :snippet
  alias_method :spammable, :snippet

  def spammable_path
    project_snippet_path(@project, @snippet)
  end
end
