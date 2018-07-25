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
        author['username']
      end

      def author_email
        author['displayName']
      end

      def note
        raw_comment['text']
      end

      def created_at
        Time.at(created_date / 1000) if created_date.is_a?(Integer)
      end

      def updated_at
        Time.at(updated_date / 1000) if created_date.is_a?(Integer)
      end

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
        raw_comment.fetch('author', {})
      end

      def created_date
        raw_comment['createdDate']
      end

      def updated_date
        raw_comment['updatedDate']
      end
    end
  end
end
