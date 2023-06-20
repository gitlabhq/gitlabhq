# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['AuditEventDefinition'], feature_category: :audit_events do
  let(:fields) do
    %i[
      name description introduced_by_issue introduced_by_mr
      feature_category milestone saved_to_database streamed
    ]
  end

  specify { expect(described_class.graphql_name).to eq('AuditEventDefinition') }
  specify { expect(described_class).to have_graphql_fields(fields) }
end
