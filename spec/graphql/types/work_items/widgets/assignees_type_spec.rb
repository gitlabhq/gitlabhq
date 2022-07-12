# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::WorkItems::Widgets::AssigneesType do
  it 'exposes the expected fields' do
    expected_fields = %i[assignees allows_multiple_assignees can_invite_members type]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
