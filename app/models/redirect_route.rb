# frozen_string_literal: true

class RedirectRoute < ApplicationRecord
  include CaseSensitivity
  include Cells::Claimable

  cells_claims_attribute :path, type: CLAIMS_BUCKET_TYPE::REDIRECT_ROUTES

  cells_claims_metadata subject_type: CLAIMS_SUBJECT_TYPE::NAMESPACE, subject_key: :namespace_id

  belongs_to :source, polymorphic: true # rubocop:disable Cop/PolymorphicAssociations

  validates :source, presence: true

  validates :path,
    length: { within: 1..255 },
    presence: true,
    uniqueness: { case_sensitive: false }

  scope :for_source_type, ->(source_type) { where(source_type: source_type) }
  scope :by_paths, ->(paths) { where(path: [paths]) }
  scope :matching_path_and_descendants, ->(path) do
    wheres = 'LOWER(redirect_routes.path) = LOWER(?) OR LOWER(redirect_routes.path) LIKE LOWER(?)'

    where(wheres, path, "#{sanitize_sql_like(path)}/%")
  end
end
