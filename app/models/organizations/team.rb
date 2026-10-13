# frozen_string_literal: true

module Organizations
  class Team < ApplicationRecord
    include Gitlab::SQL::Pattern
    include StripAttribute

    self.table_name = 'organization_teams'

    strip_attributes! :name, :path, :description

    belongs_to :organization, inverse_of: :teams, optional: false

    validates :name,
      presence: true,
      length: { maximum: 255 },
      uniqueness: { case_sensitive: false, scope: :organization_id }

    # Format only, deliberately not reserved against namespace paths: a Team path is unique
    # within its Organization and consumes no global path cardinality.
    validates :path,
      presence: true,
      length: { minimum: 2, maximum: 255 },
      format: {
        with: Gitlab::PathRegex.namespace_format_regex,
        message: Gitlab::PathRegex.namespace_format_message
      },
      uniqueness: { case_sensitive: false, scope: :organization_id }

    validates :description, length: { maximum: 2048 }

    scope :in_organization, ->(organization) { where(organization: organization) }
    # TODO: ORDER BY name cannot use the (organization_id, LOWER(name)) index; fine at current scale.
    # Evaluate a name-ordering index if larger-scale listing is ever needed:
    # https://gitlab.com/gitlab-org/gitlab/-/issues/630870
    scope :order_by_name, -> { order(:name) }

    def self.search(query, use_minimum_char_limit: true)
      fuzzy_search(query, [:name, :path], use_minimum_char_limit: use_minimum_char_limit)
    end
  end
end
