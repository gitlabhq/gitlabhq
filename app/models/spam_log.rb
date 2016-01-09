class SpamLog < ActiveRecord::Base
  belongs_to :user

  validates :user, presence: true

  def truncated_description
    if description.present? && description.length > 100
      return description[0..100] + "..."
    end

    description
  end
end
