# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['AvailableExportFields'], feature_category: :team_planning do
  specify { expect(described_class.graphql_name).to eq('AvailableExportFields') }

  describe 'enum values' do
    using RSpec::Parameterized::TableSyntax

    where(:field_name, :field_value) do
      'ID'                | 'id'
      'IID'               | 'iid'
      'ASSIGNEE'          | 'assignee'
      'ASSIGNEE_USERNAME' | 'assignee username'
      'AUTHOR'            | 'author'
      'AUTHOR_USERNAME'   | 'author username'
      'CONFIDENTIAL'      | 'confidential'
      'DESCRIPTION'       | 'description'
      'LOCKED'            | 'locked'
      'MILESTONE'         | 'milestone'
      'START_DATE'        | 'start date'
      'DUE_DATE'          | 'due date'
      'CLOSED_AT'         | 'closed at'
      'CREATED_AT'        | 'created at'
      'UPDATED_AT'        | 'updated at'
      'PARENT_ID'         | 'parent id'
      'PARENT_IID'        | 'parent iid'
      'PARENT_TITLE'      | 'parent title'
      'STATE'             | 'state'
      'TITLE'             | 'title'
      'TIME_ESTIMATE'     | 'time estimate'
      'TIME_SPENT'        | 'time spent'
      'TYPE'              | 'type'
      'URL'               | 'url'
    end

    with_them do
      it 'exposes correct available fields' do
        expect(described_class.values[field_name].value).to eq(field_value)
      end
    end
  end
end
