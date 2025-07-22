# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group labels', feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be_with_reload(:label) { create(:group_label, group: group) }

  before_all do
    group.add_owner(user)
  end

  before do
    sign_in(user)
    visit group_labels_path(group)
  end

  it_behaves_like 'handles archived labels in view'
end
