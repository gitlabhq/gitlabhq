# frozen_string_literal: true

module Releases
  class Link < ApplicationRecord
    self.table_name = 'release_links'

    belongs_to :release, touch: true

    # See https://gitlab.com/gitlab-org/gitlab/-/issues/218753
    # Regex modified to prevent catastrophic backtracking
    FILEPATH_REGEX = %r{\A\/[^\/](?!.*\/\/.*)[\-\.\w\/]+[\da-zA-Z]+\z}
    FILEPATH_MAX_LENGTH = 128

    validates :url, presence: true, addressable_url: { schemes: %w[http https ftp] }, uniqueness: { scope: :release }
    validates :name, presence: true, uniqueness: { scope: :release }
    validates :filepath, uniqueness: { scope: :release }, allow_blank: true
    validate :filepath_format_valid?

    # we use a custom validator here to prevent running the regex if the string is too long
    # see https://gitlab.com/gitlab-org/gitlab/-/issues/273771
    def filepath_format_valid?
      return if filepath.nil? # valid use case
      return errors.add(:filepath, "is too long (maximum is #{FILEPATH_MAX_LENGTH} characters)") if filepath.length > FILEPATH_MAX_LENGTH
      return errors.add(:filepath, 'is in an invalid format') unless FILEPATH_REGEX.match? filepath
    end

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

    def hook_attrs
      {
        id: id,
        link_type: link_type,
        name: name,
        url: url
      }
    end
  end
end
