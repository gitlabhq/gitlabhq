# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['AvailableExportFields'], feature_category: :team_planning do
  specify { expect(described_class.graphql_name).to eq('AvailableExportFields') }

  describe 'enum values' do
    using RSpec::Parameterized::TableSyntax

    where(:field_name, :field_value) do
      'ID'              | 'id'
      'TYPE'            | 'type'
      'TITLE'           | 'title'
      'DESCRIPTION'     | 'description'
      'AUTHOR'          | 'author'
      'AUTHOR_USERNAME' | 'author username'
      'CREATED_AT'      | 'created_at'
    end

    with_them do
      it 'exposes correct available fields' do
        expect(described_class.values[field_name].value).to eq(field_value)
      end
    end
  end
end
