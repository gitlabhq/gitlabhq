# frozen_string_literal: true

class ProjectTracingSetting < ApplicationRecord
  belongs_to :project

  validates :external_url, length: { maximum: 255 }, public_url: true

  before_validation :sanitize_external_url

  private

  def sanitize_external_url
    self.external_url = Rails::Html::FullSanitizer.new.sanitize(self.external_url)
  end
end
