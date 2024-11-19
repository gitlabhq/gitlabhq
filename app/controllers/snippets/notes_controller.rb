# frozen_string_literal: true

class Snippets::NotesController < ApplicationController
  include NotesActions
  include ToggleAwardEmoji

  skip_before_action :authenticate_user!, only: [:index]
  before_action :authorize_read_snippet!, only: [:show, :index]
  before_action :authorize_create_note!, only: [:create]

  feature_category :source_code_management

  private

  def note
    @note ||= snippet.notes.inc_relations_for_view(snippet).find(params[:id])
  end
  alias_method :awardable, :note

  def project
    nil
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def snippet
    @snippet ||= PersonalSnippet.find_by(id: params[:snippet_id])
  end
  # rubocop: enable CodeReuse/ActiveRecord
  alias_method :noteable, :snippet

  def finder_params
    params.merge(
      last_fetched_at: last_fetched_at,
      target_id: snippet.id,
      target_type: 'personal_snippet'
    ).tap do |merged_params|
      merged_params[:project] = project if respond_to?(:project)
    end
  end

  def authorize_read_snippet!
    return render_404 unless can?(current_user, :read_snippet, snippet)
  end

  def authorize_create_note!
    access_denied! unless can?(current_user, :create_note, noteable)
  end
end
