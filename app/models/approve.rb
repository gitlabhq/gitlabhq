class Approve < ActiveRecord::Base
  belongs_to :user
  belongs_to :merge_request
end
