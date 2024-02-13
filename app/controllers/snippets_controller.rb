# frozen_string_literal: true

class SnippetsController < Snippets::ApplicationController
  include SnippetsActions
  include PreviewMarkdown
  include ToggleAwardEmoji
  include SpammableActions::AkismetMarkAsSpamAction

  before_action :snippet, only: [:show, :edit, :raw, :toggle_award_emoji, :mark_as_spam]

  before_action :authorize_create_snippet!, only: :new
  before_action :authorize_read_snippet!, only: [:show, :raw]
  before_action :authorize_update_snippet!, only: :edit

  skip_before_action :authenticate_user!, only: [:index, :show, :raw]

  layout :determine_layout

  def index
    redirect_to(current_user ? dashboard_snippets_path : explore_snippets_path)
  end

  def new
    @snippet = PersonalSnippet.new
  end

  protected

  alias_method :awardable, :snippet
  alias_method :spammable, :snippet

  def spammable_path
    snippet_path(@snippet)
  end

  def determine_layout
    if action_name == 'show' && @snippet.author != current_user
      'explore'
    else
      'snippets'
    end
  end
end
