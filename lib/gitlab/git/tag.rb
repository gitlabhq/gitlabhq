# frozen_string_literal: true

module Gitlab
  module Git
    class Tag < Ref
      extend Gitlab::EncodingHelper

      attr_reader :object_sha, :repository

      MAX_TAG_MESSAGE_DISPLAY_SIZE = 10.megabytes
      SERIALIZE_KEYS = %i[name target target_commit message].freeze

      attr_accessor *SERIALIZE_KEYS # rubocop:disable Lint/AmbiguousOperator

      class << self
        def get_message(repository, tag_id)
          BatchLoader.for(tag_id).batch(key: repository) do |tag_ids, loader, args|
            get_messages(args[:key], tag_ids).each do |tag_id, message|
              loader.call(tag_id, message)
            end
          end
        end

        def get_messages(repository, tag_ids)
          repository.gitaly_ref_client.get_tag_messages(tag_ids)
        end
      end

      def initialize(repository, raw_tag)
        @repository = repository
        @raw_tag = raw_tag

        case raw_tag
        when Hash
          init_from_hash
        when Gitaly::Tag
          init_from_gitaly
        end

        super(repository, name, target, target_commit)
      end

      def init_from_hash
        raw_tag = @raw_tag.symbolize_keys

        SERIALIZE_KEYS.each do |key|
          send("#{key}=", raw_tag[key]) # rubocop:disable GitlabSecurity/PublicSend
        end
      end

      def init_from_gitaly
        @name = encode!(@raw_tag.name.dup)
        @target = @raw_tag.id
        @message = message_from_gitaly_tag

        if @raw_tag.target_commit.present?
          @target_commit = Gitlab::Git::Commit.decorate(repository, @raw_tag.target_commit)
        end
      end

      def message
        encode! @message
      end

      def tagger
        @raw_tag.tagger
      end

      private

      def message_from_gitaly_tag
        return @raw_tag.message.dup if full_message_fetched_from_gitaly?

        if @raw_tag.message_size > MAX_TAG_MESSAGE_DISPLAY_SIZE
          '--tag message is too big'
        else
          self.class.get_message(@repository, target)
        end
      end

      def full_message_fetched_from_gitaly?
        @raw_tag.message.bytesize == @raw_tag.message_size
      end
    end
  end
end
