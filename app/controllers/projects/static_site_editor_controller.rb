# frozen_string_literal: true

class Projects::StaticSiteEditorController < Projects::ApplicationController
  include ExtractsPath
  include CreatesCommit
  include BlobHelper

  layout 'fullscreen'

  content_security_policy do |policy|
    next if policy.directives.blank?

    frame_src_values = Array.wrap(policy.directives['frame-src']) | ['https://www.youtube.com']
    policy.frame_src(*frame_src_values)
  end

  prepend_before_action :authenticate_user!, only: [:show]
  before_action :assign_ref_and_path, only: [:show]
  before_action :authorize_edit_tree!, only: [:show]

  feature_category :static_site_editor

  def index
    render_404
  end

  def show
    redirect_to ide_edit_path(project, @ref, @path)
  end

  private

  def serialize_necessary_payload_values_to_json(payload)
    # This will convert booleans, Array-like and Hash-like objects to JSON
    payload.transform_values do |value|
      if value.is_a?(String) || value.is_a?(Integer)
        value
      elsif value.nil?
        ''
      else
        value.to_json
      end
    end
  end

  def assign_ref_and_path
    @ref, @path = extract_ref(params.fetch(:id))

    render_404 if @ref.blank? || @path.blank?
  end
end
