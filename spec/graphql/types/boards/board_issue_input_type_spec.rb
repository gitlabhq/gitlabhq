# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['BoardIssueInput'] do
  it { expect(described_class.graphql_name).to eq('BoardIssueInput') }

  it 'has specific fields' do
    allowed_args = %w(labelName milestoneTitle assigneeUsername authorUsername
                      releaseTag myReactionEmoji not search assigneeWildcardId)

    expect(described_class.arguments.keys).to include(*allowed_args)
    expect(described_class.arguments['not'].type).to eq(Types::Boards::NegatedBoardIssueInputType)
  end
end
