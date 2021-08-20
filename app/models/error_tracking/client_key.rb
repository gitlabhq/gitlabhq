# frozen_string_literal: true

class ErrorTracking::ClientKey < ApplicationRecord
  belongs_to :project

  validates :project, presence: true
  validates :public_key, presence: true, length: { maximum: 255 }

  scope :active, -> { where(active: true) }

  after_initialize :generate_key

  def self.find_by_public_key(key)
    find_by(public_key: key)
  end

  def sentry_dsn
    @sentry_dsn ||= ErrorTracking::Collector::Dsn.build_url(public_key, project_id)
  end

  private

  def generate_key
    self.public_key ||= "glet_#{SecureRandom.hex}"
  end
end
