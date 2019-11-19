# frozen_string_literal: true
require 'spec_helper'

describe GitlabSchema.types['Label'] do
  it 'has the correct fields' do
    expected_fields = [:id, :description, :description_html, :title, :color, :text_color]

    is_expected.to have_graphql_fields(*expected_fields)
  end

  it { is_expected.to require_graphql_authorizations(:read_label) }
end
