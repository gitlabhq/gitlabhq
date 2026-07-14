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
      attr_reader :parent_comment

      CommentNode = Struct.new(:raw_comments, :parent)

      def initialize(raw, parent_comment: nil)
        super(raw)

        @parent_comment = parent_comment
      end

      def id
        raw_comment['id']
      end

      def author_name
        author['displayName']
      end

      def author_username
        author['username'] ||
          author['slug'] ||
          author['displayName']
      end

      def author_email
        author['emailAddress']
      end

      def note
        raw_comment['text']
      end

      def created_at
        self.class.convert_timestamp(created_date)
      end

      def updated_at
        self.class.convert_timestamp(created_date)
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
        @comments ||= flatten_comments
      end

      def to_hash
        parent_comment_note = parent_comment.note if parent_comment

        {
          id: id,
          author_name: author_name,
          author_email: author_email,
          author_username: author_username,
          note: note,
          created_at: created_at,
          updated_at: updated_at,
          comments: comments.map(&:to_hash),
          parent_comment_note: parent_comment_note
        }
      end

      private

      # In order to provide context for each reply, we need to track
      # the parent of each comment. This method works as follows:
      #
      # 1. Insert the root comment into the workset. The root element is the current note.
      # 2. For each node in the workset:
      #    a. Examine if it has replies to that comment. If it does,
      #       insert that node into the workset.
      #    b. Parse that note into a Comment structure and add it to a flat list.
      def flatten_comments
        comments = raw_comment['comments']
        workset =
          if comments
            [CommentNode.new(comments, self)]
          else
            []
          end

        all_comments = []

        until workset.empty?
          node = workset.pop
          parent = node.parent

          node.raw_comments.each do |comment|
            new_comments = comment.delete('comments')
            current_comment = Comment.new({ 'comment' => comment }, parent_comment: parent)
            all_comments << current_comment
            workset << CommentNode.new(new_comments, current_comment) if new_comments
          end
        end

        all_comments
      end

      def raw_comment
        raw.fetch('comment', {})
      end

      def author
        raw_comment['author']
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
