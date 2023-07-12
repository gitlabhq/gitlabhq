# frozen_string_literal: true

module Gitlab
  module DataBuilder
    module Emoji
      extend self

      def build(award_emoji, user, action)
        project = award_emoji.awardable.project
        data = build_base_data(project, user, award_emoji, action)

        if award_emoji.awardable.is_a?(::Note)
          note = award_emoji.awardable
          data[:note] = note.hook_attrs
          noteable = note.noteable
        else
          noteable = award_emoji.awardable
        end

        if noteable.respond_to?(:hook_attrs)
          data[noteable.class.underscore.to_sym] = noteable.hook_attrs
        else
          Gitlab::AppLogger.error(
            "Error building payload data for emoji webhook. #{noteable.class} does not respond to hook_attrs.")
        end

        data
      end

      def build_base_data(project, user, award_emoji, action)
        base_data = {
          object_kind: 'emoji',
          event_type: action,
          user: user.hook_attrs,
          project_id: project.id,
          project: project.hook_attrs,
          object_attributes: award_emoji.hook_attrs
        }

        base_data[:object_attributes][:awarded_on_url] = Gitlab::UrlBuilder.build(award_emoji.awardable)
        base_data
      end
    end
  end
end
