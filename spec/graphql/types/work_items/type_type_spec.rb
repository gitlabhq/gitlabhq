# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::WorkItems::TypeType, feature_category: :team_planning do
  let(:fields) do
    %i[id icon_name name widget_definitions supported_conversion_types unavailable_widgets_on_conversion]
  end

  specify { expect(described_class.graphql_name).to eq('WorkItemType') }

  specify { expect(described_class).to have_graphql_fields(fields) }

  specify { expect(described_class).to require_graphql_authorizations(:read_work_item_type) }

  describe 'unavailable_widgets_on_conversion field' do
    it 'has the correct arguments' do
      field = described_class.fields['unavailableWidgetsOnConversion']

      expect(field).to be_present
      expect(field.arguments.keys).to contain_exactly('target')

      target_arg = field.arguments['target']

      expect(target_arg.type.to_type_signature).to eq('WorkItemsTypeID!')
    end
  end
end
