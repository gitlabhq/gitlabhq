# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::WorkItems::Widgets::DescriptionType do
  it 'exposes the expected fields' do
    expected_fields = %i[description description_html edited last_edited_at last_edited_by task_completion_status type]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
