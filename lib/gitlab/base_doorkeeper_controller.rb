# This is a base controller for doorkeeper.
# It adds the `can?` helper used in the views.
module Gitlab
  class BaseDoorkeeperController < ActionController::Base
    include Gitlab::Allowable
    helper_method :can?
  end
end
