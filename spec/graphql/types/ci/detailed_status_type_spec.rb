# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::DetailedStatusType do
  include GraphqlHelpers

  specify { expect(described_class.graphql_name).to eq('DetailedStatus') }

  it 'has all fields' do
    expect(described_class).to have_graphql_fields(:id, :group, :icon, :favicon,
                                                   :details_path, :has_details,
                                                   :label, :text, :tooltip, :action)
  end

  let_it_be(:stage) { create(:ci_stage_entity, status: :skipped) }

  describe 'id field' do
    it 'correctly renders the field' do
      parent_object = double(:parent_object, object: stage)
      parent = double(:parent, object: parent_object)
      status = stage.detailed_status(stage.pipeline.user)
      expected_id = "#{status.id}-#{stage.id}"

      expect(resolve_field('id', status, extras: { parent: parent })).to eq(expected_id)
    end
  end

  describe 'action field' do
    it 'correctly renders the field' do
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
