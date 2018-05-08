class ApplicationSetting
  class Term < ActiveRecord::Base
    include CacheMarkdownField

    validates :terms, presence: true

    cache_markdown_field :terms

    def self.latest
      order(:id).last
    end
  end
end
