# frozen_string_literal: true
module Flowdock
  class Git
    class Commit
      def initialize(external_thread_id, thread, tags, commit)
        @commit = commit
        @external_thread_id = external_thread_id
        @thread = thread
        @tags = tags
      end

      def to_hash
        hash = {
          external_thread_id: @external_thread_id,
          event: "activity",
          author: {
            name: @commit[:author][:name],
            email: @commit[:author][:email]
          },
          title: title,
          thread: @thread,
          body: body
        }
        hash[:tags] = @tags if @tags
        encode(hash)
      end

      private

      def encode(hash)
        return hash unless "".respond_to?(:encode)

        encode_as_utf8(hash)
      end

      # This only works on Ruby 1.9
      def encode_as_utf8(obj)
        if obj.is_a? Hash
          obj.each_pair do |key, val|
            encode_as_utf8(val)
          end
        elsif obj.is_a?(Array)
          obj.each do |val|
            encode_as_utf8(val)
          end
        elsif obj.is_a?(String) && obj.encoding != Encoding::UTF_8
          unless obj.force_encoding("UTF-8").valid_encoding?
            obj.force_encoding("ISO-8859-1").encode!(Encoding::UTF_8, invalid: :replace, undef: :replace)
          end
        end
      end

      def body
        content = @commit[:message][first_line.size..-1]
        content.strip! if content
        "<pre>#{content}</pre>" unless content.empty?
      end

      def first_line
        @first_line ||= (@commit[:message].split("\n")[0] || @commit[:message])
      end

      def title
        commit_id = @commit[:id][0, 7]
        if @commit[:url]
          "<a href=\"#{@commit[:url]}\">#{commit_id}</a> #{message_title}"
        else
          "#{commit_id} #{message_title}"
        end
      end

      def message_title
        CGI.escape_html(first_line.strip)
      end
    end

    # Class used to build Git payload
    class Builder
      include ::Gitlab::Utils::StrongMemoize

      def initialize(opts)
        @repo = opts[:repo]
        @ref = opts[:ref]
        @before = opts[:before]
        @after = opts[:after]
        @opts = opts
      end

      def commits
        @repo.commits_between(@before, @after).map do |commit|
          {
            url: @opts[:commit_url] ? @opts[:commit_url] % [commit.sha] : nil,
            id: commit.sha,
            message: commit.message,
            author: {
              name: commit.author_name,
              email: commit.author_email
            }
          }
        end
      end

      def ref_name
        @ref.to_s.sub(%r{\Arefs/(heads|tags)/}, '')
      end

      def to_hashes
        commits.map do |commit|
          Commit.new(external_thread_id, thread, @opts[:tags], commit).to_hash
        end
      end

      private

      def thread
        @thread ||= {
          title: thread_title,
          external_url: @opts[:repo_url]
        }
      end

      def permanent?
        strong_memoize(:permanent) do
          @opts[:permanent_refs].any? { |regex| regex.match(@ref) }
        end
      end

      def thread_title
        action = "updated" if permanent?
        type = @ref =~ %r(^refs/heads/) ? "branch" : "tag"

        [@opts[:repo_name], type, ref_name, action].compact.join(" ")
      end

      def external_thread_id
        @external_thread_id ||=
          if permanent?
            SecureRandom.hex
          else
            @ref
          end
      end
    end
  end
end
