# frozen_string_literal: true

module Types
  module DeprecatedMutations
    extend ActiveSupport::Concern

    prepended do
      mount_aliased_mutation 'AddAwardEmoji',
                             Mutations::AwardEmojis::Add,
                             deprecated: { reason: 'Use awardEmojiAdd', milestone: '13.2' }
      mount_aliased_mutation 'RemoveAwardEmoji',
                             Mutations::AwardEmojis::Remove,
                             deprecated: { reason: 'Use awardEmojiRemove', milestone: '13.2' }
      mount_aliased_mutation 'ToggleAwardEmoji',
                             Mutations::AwardEmojis::Toggle,
                             deprecated: { reason: 'Use awardEmojiToggle', milestone: '13.2' }
    end
  end
end
