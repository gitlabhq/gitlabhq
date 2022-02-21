# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['WorkItem'] do
  specify { expect(described_class.graphql_name).to eq('WorkItem') }

  specify { expect(described_class).to require_graphql_authorizations(:read_issue) }

  it 'has specific fields' do
    fields = %i[description description_html id iid lock_version state title title_html work_item_type]

    fields.each do |field_name|
      expect(described_class).to have_graphql_fields(*fields)
    end
  end
end
