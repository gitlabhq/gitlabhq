# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Blame::CommitDataType,
  feature_category: :source_code_management do
  include GraphqlHelpers

  specify { expect(described_class.graphql_name).to eq('CommitData') }

  specify do
    expect(described_class).to have_graphql_fields(
      :age_map_class,
      :author_avatar,
      :commit_author_link,
      :commit_link,
      :previous_blame_path,
      :project_blame_link,
      :time_ago_tooltip
    ).at_least
  end
end
