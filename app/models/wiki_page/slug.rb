# frozen_string_literal: true

class WikiPage
  class Slug < ApplicationRecord
    self.table_name = 'wiki_page_slugs'

    belongs_to :wiki_page_meta, class_name: 'WikiPage::Meta', inverse_of: :slugs

    validates :slug, uniqueness: { scope: :wiki_page_meta_id }
    validates :slug, length: { maximum: 2048 }, allow_nil: false
    validates :canonical, uniqueness: {
      scope: :wiki_page_meta_id,
      if: :canonical?,
      message: 'Only one slug can be canonical per wiki metadata record'
    }

    scope :canonical, -> { where(canonical: true) }

    def self.update_all(attrs = {})
      super(attrs.reverse_merge(updated_at: Time.current.utc))
    end

    def update_columns(attrs = {})
      super(attrs.reverse_merge(updated_at: Time.current.utc))
    end
  end
end
