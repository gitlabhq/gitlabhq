# frozen_string_literal: true

module Gitlab
  module QuickActions
    class UsersExtractor
      MAX_QUICK_ACTION_USERS = 100

      Error = Class.new(ArgumentError)
      TooManyError = Class.new(Error) do
        def limit
          MAX_QUICK_ACTION_USERS
        end
      end

      MissingError = Class.new(Error)
      TooManyFoundError = Class.new(TooManyError)
      TooManyRefsError = Class.new(TooManyError)

      attr_reader :text, :current_user, :project, :group, :target

      def initialize(current_user, project:, group:, target:, text:)
        @current_user = current_user
        @project = project
        @group = group
        @target = target
        @text = text
      end

      def execute
        return [] unless text.present?

        users = collect_users

        check_users!(users)

        users
      end

      private

      def collect_users
        users = []
        users << current_user if me?
        users += find_referenced_users if references.any?

        users
      end

      def check_users!(users)
        raise TooManyFoundError if users.size > MAX_QUICK_ACTION_USERS

        found = found_names(users)
        missing = references.filter_map do
          "'#{_1}'" unless found.include?(_1.downcase.delete_prefix('@'))
        end

        raise MissingError, missing.to_sentence if missing.present?
      end

      def found_names(users)
        users.map(&:username).map(&:downcase).to_set
      end

      def find_referenced_users
        raise TooManyRefsError if references.size > MAX_QUICK_ACTION_USERS

        User.by_username(usernames).limit(MAX_QUICK_ACTION_USERS)
      end

      def usernames
        references.map { _1.delete_prefix('@') }
      end

      def references
        @references ||= begin
          refs = args - ['me']
          # nb: underscores may be passed in escaped to protect them from markdown rendering
          refs.map! { _1.gsub(/\\_/, '_') }
          refs
        end
      end

      def args
        @args ||= text.split(/\s|,/).map(&:strip).select(&:present?).uniq - ['and']
      end

      def me?
        args&.include?('me')
      end
    end
  end
end

Gitlab::QuickActions::UsersExtractor.prepend_mod_with('Gitlab::QuickActions::UsersExtractor')
