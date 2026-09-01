# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['MergeRequestSavedViewNegatedFilterInput'], feature_category: :code_review_workflow do
  let(:stored_filters_schema) do
    Gitlab::Json::SafeParser.parse(
      File.read(Rails.root.join('app/validators/json_schemas/merge_request_saved_view_filters.json'))
    )
  end

  specify { expect(described_class.graphql_name).to eq('MergeRequestSavedViewNegatedFilterInput') }

  it 'accepts exactly the keys permitted by the stored filters schema' do
    expect(described_class.arguments.values.map { |argument| argument.keyword.to_s })
      .to match_array(stored_filters_schema['properties']['not']['properties'].keys)
  end

  it 'stores every argument under its own snake_case name' do
    described_class.arguments.each do |name, argument|
      expect(argument.keyword.to_s).to eq(name.underscore)
    end
  end
end
