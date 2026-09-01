# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['MergeRequestSavedViewFilterInput'], feature_category: :code_review_workflow do
  let(:stored_filters_schema) do
    Gitlab::Json::SafeParser.parse(
      File.read(Rails.root.join('app/validators/json_schemas/merge_request_saved_view_filters.json'))
    )
  end

  specify { expect(described_class.graphql_name).to eq('MergeRequestSavedViewFilterInput') }

  it 'accepts exactly the keys permitted by the stored filters schema' do
    expect(described_class.arguments.values.map { |argument| argument.keyword.to_s })
      .to match_array(stored_filters_schema['properties'].keys)
  end

  it 'stores every argument under its own snake_case name' do
    described_class.arguments.each do |name, argument|
      expect(argument.keyword.to_s).to eq(name.underscore)
    end
  end

  it 'accepts exactly the states permitted by the stored filters schema' do
    expect(described_class.arguments['state'].type.values.keys)
      .to match_array(stored_filters_schema['properties']['state']['enum'])
  end

  it 'accepts exactly the sorts permitted by the stored filters schema' do
    expect(described_class.arguments['sort'].type.values.values.map { |value| value.value.to_s }.uniq)
      .to match_array(stored_filters_schema['properties']['sort']['enum'])
  end

  it 'nests the negated filters under the negated input type' do
    expect(described_class.arguments['not'].type).to eq(Types::MergeRequests::SavedViewNegatedFilterInputType)
  end
end
