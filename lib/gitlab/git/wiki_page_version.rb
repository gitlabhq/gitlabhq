# frozen_string_literal: true

module Gitlab
  module Git
    class WikiPageVersion
      include Gitlab::Utils::StrongMemoize

      attr_reader :commit, :format

      def initialize(commit, format)
        @commit = commit
        @format = format
      end

      delegate :message, :sha, :id, :author_name, :author_email, :authored_date, to: :commit

      def author
        strong_memoize(:author) do
          ::User.find_by_any_email(author_email)
        end
      end
    end
  end
end
