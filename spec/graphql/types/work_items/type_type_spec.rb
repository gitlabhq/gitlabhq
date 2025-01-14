# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::WorkItems::TypeType, feature_category: :team_planning do
  let(:fields) do
    %i[id icon_name name widget_definitions supported_conversion_types]
  end

  specify { expect(described_class.graphql_name).to eq('WorkItemType') }

  specify { expect(described_class).to have_graphql_fields(fields) }

  specify { expect(described_class).to require_graphql_authorizations(:read_work_item_type) }
end
