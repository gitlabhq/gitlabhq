# frozen_string_literal: true

module SnippetsActions
  extend ActiveSupport::Concern

  def edit
  end

  def raw
    disposition = params[:inline] == 'false' ? 'attachment' : 'inline'

    workhorse_set_content_type!

    send_data(
      convert_line_endings(blob.data),
      type: 'text/plain; charset=utf-8',
      disposition: disposition,
      filename: Snippet.sanitized_file_name(blob.name)
    )
  end

  def js_request?
    request.format.js?
  end

  private

  def convert_line_endings(content)
    params[:line_ending] == 'raw' ? content : content.gsub(/\r\n/, "\n")
  end

  def check_repository_error
    repository_errors = Array(snippet.errors.delete(:repository))

    flash.now[:alert] = repository_errors.first if repository_errors.present?
    recaptcha_check_with_fallback(repository_errors.empty?) { render :edit }
  end
end
