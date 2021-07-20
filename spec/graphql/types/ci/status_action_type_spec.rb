# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::StatusActionType do
  include GraphqlHelpers

  specify { expect(described_class.graphql_name).to eq('StatusAction') }

  it 'exposes the expected fields' do
    expected_fields = %i[
      id
      buttonTitle
      icon
      path
      method
      title
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  describe 'id field' do
    it 'correctly renders the field' do
      stage = build(:ci_stage_entity, status: :skipped)
      status = stage.detailed_status(stage.pipeline.user)

      grandparent_object = double(:grandparent_object, object: stage)
      parent_object = double(:parent_object, object: status)

      grandparent = double(:parent, object: grandparent_object)
      parent = double(:parent, object: parent_object, parent: grandparent)

      expected_id = "#{stage.class.name}-#{status.id}"

      expect(resolve_field('id', status, extras: { parent: parent })).to eq(expected_id)
    end
  end
end
