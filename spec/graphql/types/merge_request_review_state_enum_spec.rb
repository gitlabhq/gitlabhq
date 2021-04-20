# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['MergeRequestReviewState'] do
  it 'the correct enum members' do
    expect(described_class.values).to match(
      'REVIEWED' => have_attributes(
        description: 'The merge request is reviewed.',
        value: 'reviewed'
      ),
      'UNREVIEWED' => have_attributes(
        description: 'The merge request is unreviewed.',
        value: 'unreviewed'
      )
    )
  end
end
