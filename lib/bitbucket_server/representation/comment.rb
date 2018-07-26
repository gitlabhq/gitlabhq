# frozen_string_literal: true

module BitbucketServer
  module Representation
    # A general comment with the structure:
    # "comment": {
    #   "author": {
    #               "active": true,
    #               "displayName": "root",
    #               "emailAddress": "stanhu+bitbucket@gitlab.com",
    #               "id": 1,
    #               "links": {
    #                 "self": [
    #                   {
    #                     "href": "http://localhost:7990/users/root"
    #                   }
    #                 ]
    #                },
    #                "name": "root",
    #                "slug": "root",
    #                "type": "NORMAL"
    #               }
    #   }
    # }
    class Comment < Representation::Base
      def id
        raw_comment['id']
      end

      def author_username
        author['displayName']
      end

      def author_email
        author['emailAddress']
      end

      def note
        raw_comment['text']
      end

      def created_at
        Time.at(created_date / 1000) if created_date.is_a?(Integer)
      end

      def updated_at
        Time.at(updated_date / 1000) if updated_date.is_a?(Integer)
      end

      # Bitbucket Server supports the ability to reply to any comment
      # and created multiple threads. It represents these as a linked list
      # of comments within comments. For example:
      #
      # "comments": [
      #    {
      #       "author" : ...
      #       "comments": [
      #          {
      #             "author": ...
      #
      # Since GitLab only supports a single thread, we flatten all these
      # comments into a single discussion.
      def comments
        workset = [raw_comment['comments']].compact
        all_comments = []

        until workset.empty?
          comments = workset.pop

          comments.each do |comment|
            new_comments = comment.delete('comments')
            workset << new_comments if new_comments
            all_comments << Comment.new({ 'comment' => comment })
          end
        end

        all_comments
      end

      private

      def raw_comment
        raw.fetch('comment', {})
      end

      def author
        raw.dig('comment', 'author')
      end

      def created_date
        raw.dig('comment', 'createdDate')
      end

      def updated_date
        raw.dig('comment', 'updatedDate')
      end
    end
  end
end
