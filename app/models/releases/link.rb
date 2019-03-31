# frozen_string_literal: true

module Releases
  class Link < ApplicationRecord
    self.table_name = 'release_links'

    belongs_to :release

    validates :url, presence: true, url: { protocols: %w(http https ftp) }, uniqueness: { scope: :release }
    validates :name, presence: true, uniqueness: { scope: :release }

    scope :sorted, -> { order(created_at: :desc) }

    def internal?
      url.start_with?(release.project.web_url)
    end

    def external?
      !internal?
    end
  end
end
