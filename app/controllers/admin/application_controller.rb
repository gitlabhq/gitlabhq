# frozen_string_literal: true

# Provides a base class for Admin controllers to subclass
#
# Automatically sets the layout and ensures an administrator is logged in
class Admin::ApplicationController < ApplicationController
  include EnforcesAdminAuthentication

  layout 'admin'
end

Admin::ApplicationController.prepend_if_ee('EE::Admin::ApplicationController')
