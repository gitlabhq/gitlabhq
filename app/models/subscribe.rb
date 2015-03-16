class Subscribe < ActiveRecord::Base
  belongs_to :user

  validates :issue_id, uniqueness: { scope: :user_id, allow_nil: true }
  validates :merge_request_id, uniqueness: { scope: :user_id, allow_nil: true }
end
