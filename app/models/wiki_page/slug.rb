# frozen_string_literal: true

class WikiPage
  class Slug < ApplicationRecord
    def self.meta_foreign_key
      :wiki_page_meta_id
    end

    include HasWikiPageSlugAttributes

    self.table_name = 'wiki_page_slugs'

    belongs_to :wiki_page_meta, class_name: 'WikiPage::Meta', inverse_of: :slugs
  end
end
