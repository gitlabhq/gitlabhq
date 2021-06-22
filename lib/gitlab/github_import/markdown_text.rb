# frozen_string_literal: true

module Gitlab
  module GithubImport
    class MarkdownText
      include Gitlab::EncodingHelper

      def self.format(*args)
        new(*args).to_s
      end

      # text - The Markdown text as a String.
      # author - An instance of `Gitlab::GithubImport::Representation::User`
      # exists - Boolean that indicates the user exists in the GitLab database.
      def initialize(text, author, exists = false)
        @text = text.to_s
        @author = author
        @exists = exists
      end

      def to_s
        # Gitlab::EncodingHelper#clean remove `null` chars from the string
        clean(format)
      end

      private

      attr_reader :text, :author, :exists

      def format
        if author&.login.present? && !exists
          "*Created by: #{author.login}*\n\n#{text}"
        else
          text
        end
      end
    end
  end
end
