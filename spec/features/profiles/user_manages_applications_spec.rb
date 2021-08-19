# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User manages applications' do
  let_it_be(:user) { create(:user) }
  let_it_be(:new_application_path) { applications_profile_path }

  before do
    sign_in(user)
  end

  include_examples 'manage applications'
end
