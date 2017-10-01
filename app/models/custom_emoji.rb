require 'carrierwave/orm/activerecord'

class CustomEmoji < ActiveRecord::Base
  belongs_to :namespace

  mount_uploader :file, CustomEmojiUploader

  validates_integrity_of :file
  validates :name, exclusion: { in: Gitlab::Emoji.emojis_names }

  validate :file_type


  def url
    Rails.application.routes.url_helpers.root_url + file.url
  end

  private

  def file_type
    self.errors.add :file, 'Only images allowed' unless self.file.image?
  end
end
