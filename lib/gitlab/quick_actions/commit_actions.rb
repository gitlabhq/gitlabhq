# frozen_string_literal: true

module Gitlab
  module QuickActions
    module CommitActions
      extend ActiveSupport::Concern
      include Gitlab::QuickActions::Dsl

      included do
        # Commit only quick actions definitions
        desc 'Tag this commit.'
        explanation do |tag_name, message|
          with_message = %{ with "#{message}"} if message.present?
          "Tags this commit to #{tag_name}#{with_message}."
        end
        params 'v1.2.3 <message>'
        parse_params do |tag_name_and_message|
          tag_name_and_message.split(' ', 2)
        end
        types Commit
        condition do
          current_user.can?(:push_code, project)
        end
        command :tag do |tag_name, message|
          @updates[:tag_name] = tag_name
          @updates[:tag_message] = message
        end
      end
    end
  end
end
