# frozen_string_literal: true

module Organizations
  class OrganizationDetail < ApplicationRecord
    include CacheMarkdownField
    include Avatarable
    include WithUploads

    cache_markdown_field :description

    belongs_to :organization, inverse_of: :organization_detail

    validates :organization, presence: true
    validates :description, length: { maximum: 1024 }
  end
end
