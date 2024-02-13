# frozen_string_literal: true

module Organizations
  class GroupsController < ApplicationController
    feature_category :cell

    def new
      authorize_create_group!
    end
  end
end
