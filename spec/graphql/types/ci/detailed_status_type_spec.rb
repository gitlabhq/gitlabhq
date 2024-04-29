# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::DetailedStatusType do
  include GraphqlHelpers

  let_it_be(:stage) { create(:ci_stage, status: :skipped) }

  specify { expect(described_class.graphql_name).to eq('DetailedStatus') }

  it 'has all fields' do
    expect(described_class).to have_graphql_fields(
      :id, :group, :icon, :favicon,
      :details_path, :has_details,
      :label, :name, :text, :tooltip,
      :action
    )
  end

  describe 'id field' do
    it 'correctly renders the field' do
      status = stage.detailed_status(stage.pipeline.user)
      expected_id = "#{status.id}-#{stage.id}"

      expect(resolve_field('id', status, extras: { parent: stage }, arg_style: :internal)).to eq(expected_id)
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
        title: status.action_title,
        confirmation_message: status.confirmation_message
      }

      expect(resolve_field('action', status, arg_style: :internal)).to eq(expected_status)
    end
  end
end
