# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::GroupsHelper, feature_category: :groups_and_projects do
  describe '#admin_groups_app_data' do
    it 'returns expected json' do
      expect(Gitlab::Json.parse(helper.admin_groups_app_data)).to eq(
        {
          'base_path' => '/admin/groups'
        }
      )
    end
  end
end
