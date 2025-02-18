# frozen_string_literal: true

module BlobViewer
  class Markup < Base
    include Rich
    include ServerSide

    self.partial_name = 'markup'
    self.extensions = Gitlab::MarkupHelper::EXTENSIONS
    self.file_types = %i[readme]
    self.binary = false

    def banzai_render_context
      {}.tap do |h|
        h[:rendered] = blob.rendered_markup if blob.respond_to?(:rendered_markup)
        h[:issuable_reference_expansion_enabled] = true
        h[:cache_key] = ['blob', blob.id, 'commit', blob.commit_id]
      end
    end
  end
end
