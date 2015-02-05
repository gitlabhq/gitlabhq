# == Schema Information
#
# Table name: identities
#
#  id         :integer          not null, primary key
#  extern_uid :string(255)
#  provider   :string(255)
#  user_id    :integer
#

class Identity < ActiveRecord::Base
  include Sortable
  belongs_to :user

  validates :extern_uid, allow_blank: true, uniqueness: { scope: :provider }
end
