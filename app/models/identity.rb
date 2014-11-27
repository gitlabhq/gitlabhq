class Identity < ActiveRecord::Base
  belongs_to :user

  validates :extern_uid, allow_blank: true, uniqueness: {scope: :provider}
end