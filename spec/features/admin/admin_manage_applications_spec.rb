# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin manage applications', feature_category: :system_access do
  let_it_be(:new_application_path) { new_admin_application_path }
  let_it_be(:applications_path) { admin_applications_path }
  let_it_be(:index_path) { admin_applications_path }

  before do
    admin = create(:admin)
    sign_in(admin)
    enable_admin_mode!(admin)
  end

  include_examples 'manage applications'
end
