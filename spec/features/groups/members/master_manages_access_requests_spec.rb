# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Groups > Members > Maintainer manages access requests', feature_category: :groups_and_projects do
  it_behaves_like 'Maintainer manages access requests' do
    let(:entity) { create(:group, :public) }
    let(:members_page_path) { group_group_members_path(entity) }
  end
end
