# frozen_string_literal: true

module Repositories
  class ApplicationController < ::ApplicationController
    skip_before_action :authenticate_user!
  end
end
