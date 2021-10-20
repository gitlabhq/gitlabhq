# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['BoardList'] do
  include GraphqlHelpers
  include Gitlab::Graphql::Laziness

  specify { expect(described_class.graphql_name).to eq('BoardList') }

  it 'has specific fields' do
    expected_fields = %w[id title list_type position label issues_count issues]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end

  describe 'issues field' do
    subject { described_class.fields['issues'] }

    it 'has a correct extension' do
      is_expected.to have_graphql_extension(Gitlab::Graphql::Board::IssuesConnectionExtension)
    end
  end

  describe 'title' do
    subject(:field) { described_class.fields['title'] }

    it 'preloads the label association' do
      a, b, c = create_list(:list, 3).map { _1.class.find(_1.id) }

      baseline = ActiveRecord::QueryRecorder.new { force(resolve_field(field, a)) }

      expect do
        [resolve_field(field, b), resolve_field(field, c)].each { force _1 }
      end.not_to exceed_query_limit(baseline)
    end
  end
end
