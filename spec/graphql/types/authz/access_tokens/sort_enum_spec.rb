# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Authz::AccessTokens::SortEnum, feature_category: :permissions do
  specify { expect(described_class.graphql_name).to eq('AccessTokenSort') }

  it 'exposes the expected sort values' do
    expect(described_class.values).to match(
      'CREATED_DESC' => have_attributes(
        value: 'created_desc'
      ),
      'CREATED_ASC' => have_attributes(
        value: 'created_asc'
      ),
      'UPDATED_DESC' => have_attributes(
        value: 'updated_desc'
      ),
      'UPDATED_ASC' => have_attributes(
        value: 'updated_asc'
      ),
      'EXPIRES_DESC' => have_attributes(
        value: 'expires_desc'
      ),
      'EXPIRES_ASC' => have_attributes(
        value: 'expires_asc'
      ),
      'LAST_USED_DESC' => have_attributes(
        value: 'last_used_desc'
      ),
      'LAST_USED_ASC' => have_attributes(
        value: 'last_used_asc'
      ),
      'ID_DESC' => have_attributes(
        value: 'id_desc'
      ),
      'ID_ASC' => have_attributes(
        value: 'id_asc'
      ),
      'NAME_DESC' => have_attributes(
        value: 'name_desc'
      ),
      'NAME_ASC' => have_attributes(
        value: 'name_asc'
      )
    )
  end
end
