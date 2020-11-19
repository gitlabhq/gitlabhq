# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::DetailedStatusType do
  include GraphqlHelpers

  specify { expect(described_class.graphql_name).to eq('DetailedStatus') }

  it 'has all fields' do
    expect(described_class).to have_graphql_fields(:group, :icon, :favicon,
                                                   :details_path, :has_details,
                                                   :label, :text, :tooltip, :action)
  end

  describe 'action field' do
    it 'correctly renders the field' do
      stage = create(:ci_stage_entity, status: :skipped)
      status = stage.detailed_status(stage.pipeline.user)

      expected_status = {
          button_title: status.action_button_title,
          icon: status.action_icon,
          method: status.action_method,
          path: status.action_path,
          title: status.action_title
        }

      expect(resolve_field('action', status)).to eq(expected_status)
    end
  end
end
