# frozen_string_literal: true

module Gitlab
  module Git
    class WikiPageVersion
      attr_reader :commit, :format

      def initialize(commit, format)
        @commit = commit
        @format = format
      end

      delegate :message, :sha, :id, :author_name, :author_email, :authored_date, to: :commit

      def author_url
        user = ::User.find_by_any_email(author_email)
        user.nil? ? "mailto:#{author_email}" : Gitlab::UrlBuilder.build(user)
      end
    end
  end
end
