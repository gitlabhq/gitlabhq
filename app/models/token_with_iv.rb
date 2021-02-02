# frozen_string_literal: true

# rubocop: todo Gitlab/NamespacedClass
class TokenWithIv < ApplicationRecord
  validates :hashed_token, presence: true
  validates :iv, presence: true
  validates :hashed_plaintext_token, presence: true

  def self.find_by_hashed_token(value)
    find_by(hashed_token: ::Digest::SHA256.digest(value))
  end

  def self.find_by_plaintext_token(value)
    find_by(hashed_plaintext_token: ::Digest::SHA256.digest(value))
  end

  def self.find_nonce_by_hashed_token(value)
    return unless table_exists?

    token_record = find_by_hashed_token(value)
    token_record&.iv
  end
end
