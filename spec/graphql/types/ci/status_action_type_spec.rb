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
      confirmation_message
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  describe 'id field' do
    it 'correctly renders the field' do
      stage = build(:ci_stage, status: :skipped)
      status = stage.detailed_status(stage.pipeline.user)

      expected_id = "#{stage.class.name}-#{status.id}"

      expect(resolve_field('id', status, extras: { parent: status }, arg_style: :internal)).to eq(expected_id)
    end
  end
end
