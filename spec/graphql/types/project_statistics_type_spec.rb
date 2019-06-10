# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema.types['ProjectStatistics'] do
  it "has all the required fields" do
    is_expected.to have_graphql_fields(:storage_size, :repository_size, :lfs_objects_size,
                                       :build_artifacts_size, :packages_size, :commit_count,
                                       :wiki_size)
  end
end
