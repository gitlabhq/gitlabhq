# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User manages applications', feature_category: :groups_and_projects do
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:new_application_path) { group_settings_applications_path(group) }
  let_it_be(:index_path) { group_settings_applications_path(group) }

  before do
    group.add_owner(user)
    sign_in(user)
  end

  include_examples 'manage applications'
end
