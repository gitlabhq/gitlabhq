# frozen_string_literal: true

class ApplicationSetting
  class Term < ApplicationRecord
    include CacheMarkdownField

    has_many :term_agreements

    cache_markdown_field :terms

    validates :terms, presence: true

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
