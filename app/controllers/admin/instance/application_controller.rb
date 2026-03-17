# frozen_string_literal: true

module Admin
  module Instance
    class ApplicationController < Admin::ApplicationController
    end
  end
end

Admin::Instance::ApplicationController.prepend_mod_with('Admin::Instance::ApplicationController')
