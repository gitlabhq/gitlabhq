# frozen_string_literal: true

module Gitlab
  module Git
    class WikiPageVersion
      attr_reader :commit, :format

      def initialize(commit, format)
        @commit = commit
        @format = format
      end

      delegate :message, :sha, :id, :author_name, :authored_date, to: :commit
    end
  end
end
