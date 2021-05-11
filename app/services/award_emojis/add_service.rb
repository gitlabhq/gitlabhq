# frozen_string_literal: true

module AwardEmojis
  class AddService < AwardEmojis::BaseService
    include Gitlab::Utils::StrongMemoize

    def execute
      unless awardable.user_can_award?(current_user)
        return error('User cannot award emoji to awardable', status: :forbidden)
      end

      unless awardable.emoji_awardable?
        return error('Awardable cannot be awarded emoji', status: :unprocessable_entity)
      end

      award = awardable.award_emoji.create(name: name, user: current_user)

      if award.persisted?
        after_create(award)
        success(award: award)
      else
        error(award.errors.full_messages, award: award)
      end
    end

    private

    def after_create(award)
      TodoService.new.new_award_emoji(todoable, current_user) if todoable
    end

    def todoable
      strong_memoize(:todoable) do
        case awardable
        when Note
          # We don't create todos for personal snippet comments for now
          awardable.noteable unless awardable.for_personal_snippet?
        when MergeRequest, Issue
          awardable
        else
          # No todos for all other awardables
          nil
        end
      end
    end
  end
end

AwardEmojis::AddService.prepend_mod_with('AwardEmojis::AddService')
