# frozen_string_literal: true

module Releases
  class Link < ApplicationRecord
    self.table_name = 'release_links'

    belongs_to :release, touch: true

    # See https://gitlab.com/gitlab-org/gitlab/-/issues/218753
    # Regex modified to prevent catastrophic backtracking
    FILEPATH_REGEX = %r{\A\/[^\/](?!.*\/\/.*)[\-\.\w\/]+[\da-zA-Z]+\z}.freeze

    validates :url, presence: true, addressable_url: { schemes: %w(http https ftp) }, uniqueness: { scope: :release }
    validates :name, presence: true, uniqueness: { scope: :release }
    validates :filepath, uniqueness: { scope: :release }, format: { with: FILEPATH_REGEX }, allow_blank: true, length: { maximum: 128 }

    scope :sorted, -> { order(created_at: :desc) }

    enum link_type: {
      other: 0,
      runbook: 1,
      package: 2,
      image: 3
    }

    def internal?
      url.start_with?(release.project.web_url)
    end

    def external?
      !internal?
    end

    def hook_attrs
      {
        id: id,
        external: external?,
        link_type: link_type,
        name: name,
        url: url
      }
    end
  end
end
