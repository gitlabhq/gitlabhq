# frozen_string_literal: true

module Wikis
  class UserMention < UserMention
    self.table_name = 'wiki_page_meta_user_mentions'

    belongs_to :wiki_page_meta, class_name: 'WikiPage::Meta', optional: false
    belongs_to :note, optional: false

    before_validation :set_namespace_id_from_note, on: :create

    private

    def set_namespace_id_from_note
      self.namespace_id ||= note&.namespace_id
    end
  end
end
