# frozen_string_literal: true

module Snippets::SendBlob
  include SendsBlob

  def send_snippet_blob(snippet, blob)
    workhorse_set_content_type!

    send_blob(
      snippet.repository,
      blob,
      inline: content_disposition == 'inline',
      allow_caching: snippet.public?
    )
  end

  private

  def content_disposition
    @disposition ||= params[:inline] == 'false' ? 'attachment' : 'inline'
  end
end
