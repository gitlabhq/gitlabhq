# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AwardEmojisFinder do
  let_it_be(:issue_1) { create(:issue) }
  let_it_be(:issue_1_thumbsup) { create(:award_emoji, name: AwardEmoji::THUMBS_UP, awardable: issue_1) }
  let_it_be(:issue_1_thumbsdown) { create(:award_emoji, name: AwardEmoji::THUMBS_DOWN, awardable: issue_1) }
  # Create a matching set of emoji for a second issue.
  # These should never appear in our finder results
  let_it_be(:issue_2) { create(:issue) }
  let_it_be(:issue_2_thumbsup) { create(:award_emoji, name: AwardEmoji::THUMBS_UP, awardable: issue_2) }
  let_it_be(:issue_2_thumbsdown) { create(:award_emoji, name: AwardEmoji::THUMBS_DOWN, awardable: issue_2) }

  describe 'param validation' do
    it 'raises an error if `awarded_by` is invalid' do
      expectation = [ArgumentError, 'Invalid awarded_by param']

      expect { described_class.new(issue_1, { awarded_by: issue_2 }).execute }.to raise_error(*expectation)
      expect { described_class.new(issue_1, { awarded_by: 'not-an-id' }).execute }.to raise_error(*expectation)
      expect { described_class.new(issue_1, { awarded_by: 1.123 }).execute }.to raise_error(*expectation)
    end
  end

  describe '#execute' do
    it 'scopes to the awardable' do
      expect(described_class.new(issue_1).execute).to contain_exactly(
        issue_1_thumbsup, issue_1_thumbsdown
      )
    end

    it 'filters by emoji name' do
      expect(described_class.new(issue_1, { name: AwardEmoji::THUMBS_UP }).execute).to contain_exactly(issue_1_thumbsup)
      expect(described_class.new(issue_1, { name: '8ball' }).execute).to be_empty
    end

    it 'filters by user' do
      expect(described_class.new(issue_1, { awarded_by: issue_1_thumbsup.user }).execute).to contain_exactly(issue_1_thumbsup)
      expect(described_class.new(issue_1, { awarded_by: issue_2_thumbsup.user }).execute).to be_empty
    end
  end
end
