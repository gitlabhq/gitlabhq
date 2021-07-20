# frozen_string_literal: true

class ApplicationSetting
  class Term < ApplicationRecord
    include CacheMarkdownField
    include NullifyIfBlank

    has_many :term_agreements

    cache_markdown_field :terms

    nullify_if_blank :terms

    def self.latest
      order(:id).last
    end

    def accepted_by_user?(user)
      return true if user.project_bot?

      user.accepted_term_id == id ||
        term_agreements.accepted.where(user: user).exists?
    end
  end
end
