# frozen_string_literal: true

class WikiPage
  class Meta < ApplicationRecord
    include HasWikiPageMetaAttributes

    self.table_name = 'wiki_page_meta'

    belongs_to :project

    has_many :slugs, class_name: 'WikiPage::Slug', foreign_key: 'wiki_page_meta_id', inverse_of: :wiki_page_meta

    validates :project_id, presence: true

    alias_method :resource_parent, :project

    def self.container_key
      :project_id
    end
  end
end
