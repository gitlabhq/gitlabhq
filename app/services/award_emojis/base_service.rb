# frozen_string_literal: true

module AwardEmojis
  class BaseService < ::BaseService
    attr_accessor :awardable, :name

    def initialize(awardable, name, current_user)
      @awardable = awardable
      @name = normalize_name(name)

      super(awardable.project, current_user)
    end

    def execute_hooks(award_emoji, action)
      return unless awardable.project&.has_active_hooks?(:emoji_hooks)

      hook_data = Gitlab::DataBuilder::Emoji.build(award_emoji, current_user, action)
      awardable.project.execute_hooks(hook_data, :emoji_hooks)
    end

    private

    def normalize_name(name)
      TanukiEmoji.find_by_alpha_code(name)&.name || name
    end

    # Provide more error state data than what BaseService allows.
    # - An array of errors
    # - The `AwardEmoji` if present
    def error(errors, award: nil, status: nil)
      errors = Array.wrap(errors)

      super(errors.to_sentence.presence, status).merge({
        award: award,
        errors: errors
      })
    end
  end
end
