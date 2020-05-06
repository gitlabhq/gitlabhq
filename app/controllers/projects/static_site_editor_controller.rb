# frozen_string_literal: true

class Projects::StaticSiteEditorController < Projects::ApplicationController
  include ExtractsPath
  include CreatesCommit

  layout 'fullscreen'

  prepend_before_action :authenticate_user!, only: [:show]
  before_action :assign_ref_and_path, only: [:show]
  before_action :authorize_edit_tree!, only: [:show]

  before_action do
    push_frontend_feature_flag(:rich_content_editor)
  end

  def show
    @config = Gitlab::StaticSiteEditor::Config.new(@repository, @ref, @path, params[:return_url])
  end

  private

  def assign_ref_and_path
    @ref, @path = extract_ref(params[:id])

    render_404 if @ref.blank? || @path.blank?
  end
end
