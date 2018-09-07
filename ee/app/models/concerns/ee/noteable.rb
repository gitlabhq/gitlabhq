# frozen_string_literal: true

module EE
  module Noteable
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    override :note_etag_key
    def note_etag_key
      if self.is_a?(Epic)
        ::Gitlab::Routing.url_helpers.group_epic_notes_path(group, self)
      else
        super
      end
    end
  end
end
