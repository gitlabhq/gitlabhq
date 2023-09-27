# frozen_string_literal: true

module Snippets::BlobsActions
  extend ActiveSupport::Concern

  include Gitlab::Utils::StrongMemoize
  include Snippets::SendBlob

  included do
    before_action :authorize_read_snippet!, only: [:raw]
    before_action :ensure_repository
    before_action :ensure_blob
  end

  def raw
    send_snippet_blob(snippet, blob)
  end

  private

  def blob
    ref_extractor = ExtractsRef::RefExtractor.new(snippet, params.permit(:id, :ref, :path, :ref_type))
    ref_extractor.extract!
    return unless ref_extractor.commit

    snippet.repository.blob_at(ref_extractor.commit.id, ref_extractor.path)
  end
  strong_memoize_attr :blob

  def ensure_blob
    render_404 unless blob
  end

  def ensure_repository
    return if snippet.repo_exists?

    Gitlab::AppLogger.error(message: "Snippet raw blob attempt with no repo", snippet: snippet.id)

    respond_422
  end

  def snippet_id
    params[:snippet_id]
  end
end

Snippets::BlobsActions.prepend_mod
