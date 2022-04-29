# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Projects::TopicType do
  specify { expect(described_class.graphql_name).to eq('Topic') }

  specify do
    expect(described_class).to have_graphql_fields(
      :id,
      :name,
      :title,
      :description,
      :description_html,
      :avatar_url
    )
  end
end
