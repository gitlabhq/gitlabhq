# frozen_string_literal: true

module DiffForPath
  include Gitlab::Utils::StrongMemoize
  extend ActiveSupport::Concern

  def render_diff_for_path(diffs)
    diff_file = diffs.diff_files.find do |diff|
      diff.file_identifier == file_identifier_param
    end

    return render_404 unless diff_file

    render json: { html: view_to_html_string('projects/diffs/_content', diff_file: diff_file) }
  end

  private

  def file_identifier_param
    params.permit(:file_identifier)[:file_identifier]
  end
  strong_memoize_attr :file_identifier_param
end
