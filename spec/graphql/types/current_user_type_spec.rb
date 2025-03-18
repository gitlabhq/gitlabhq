# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CurrentUser'], feature_category: :user_profile do
  specify { expect(described_class.graphql_name).to eq('CurrentUser') }

  it "inherits authorization policies from the UserType superclass" do
    expect(described_class).to require_graphql_authorizations(:read_user)
  end

  describe 'work_items field' do
    subject { described_class.fields['workItems'] }

    it "finds work_items" do
      expected_fields = %i[after
        assigneeUsernames
        assigneeWildcardId
        authorUsername
        before
        closedAfter
        closedBefore
        confidential
        createdAfter
        createdBefore
        dueAfter
        dueBefore
        first
        iids
        in
        labelName
        last
        milestoneTitle
        milestoneWildcardId
        myReactionEmoji
        not
        or
        search
        sort
        state
        subscribed
        types
        updatedAfter
        updatedBefore]

      is_expected.to have_graphql_arguments(expected_fields)
      is_expected.to have_graphql_type(Types::WorkItemType.connection_type)
    end
  end
end
