# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User manages applications', feature_category: :user_profile do
  let_it_be(:user) { create(:user) }
  let_it_be(:new_application_path) { user_settings_applications_path }
  let_it_be(:index_path) { oauth_applications_path }

  before do
    sign_in(user)
  end

  include_examples 'manage applications'
end
