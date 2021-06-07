# frozen_string_literal: true

class UserDetail < ApplicationRecord
  extend ::Gitlab::Utils::Override
  include CacheMarkdownField

  belongs_to :user

  validates :pronouns, length: { maximum: 50 }
  validates :job_title, length: { maximum: 200 }
  validates :bio, length: { maximum: 255 }, allow_blank: true

  before_save :prevent_nil_bio

  cache_markdown_field :bio

  def bio_html
    read_attribute(:bio_html) || bio
  end

  # For backward compatibility.
  # Older migrations (and their tests) reference the `User.migration_bot` where the `bio` attribute is set.
  # Here we disable writing the markdown cache when the `bio_html` column does not exist.
  override :invalidated_markdown_cache?
  def invalidated_markdown_cache?
    self.class.column_names.include?('bio_html') && super
  end

  private

  def prevent_nil_bio
    self.bio = '' if bio_changed? && bio.nil?
  end
end

UserDetail.prepend_mod_with('UserDetail')
