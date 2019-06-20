# frozen_string_literal: true
require 'spec_helper'

describe GitlabSchema.types['Label'] do
  it 'has the correct fields' do
    expected_fields = [:description, :description_html, :title, :color, :text_color]

    is_expected.to have_graphql_fields(*expected_fields)
  end
end
