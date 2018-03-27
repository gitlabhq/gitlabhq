# frozen_string_literal: true

module Gitlab
  module GithubImport
    class MarkdownText
      attr_reader :text, :author, :exists

      def self.format(*args)
        new(*args).to_s
      end

      # text - The Markdown text as a String.
      # author - An instance of `Gitlab::GithubImport::Representation::User`
      # exists - Boolean that indicates the user exists in the GitLab database.
      def initialize(text, author, exists = false)
        @text = text
        @author = author
        @exists = exists
      end

      def to_s
        if exists
          text
        else
          "*Created by: #{author.login}*\n\n#{text}"
        end
      end
    end
  end
end
