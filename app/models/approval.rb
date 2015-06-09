class Approval < ActiveRecord::Base
  belongs_to :user
  belongs_to :merge_request
end
