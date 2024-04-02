# frozen_string_literal: true

module Gitlab
  module Git
    class Tag < Ref
      extend Gitlab::EncodingHelper

      delegate :id, to: :@raw_tag

      attr_reader :object_sha, :repository

      MAX_TAG_MESSAGE_DISPLAY_SIZE = 10.megabytes
      SERIALIZE_KEYS = %i[name target target_commit message].freeze

      attr_accessor(*SERIALIZE_KEYS)

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

        def extract_signature_lazily(repository, tag_id)
          BatchLoader.for(tag_id).batch(key: repository) do |tag_ids, loader, args|
            batch_signature_extraction(args[:key], tag_ids).each do |tag_id, signature_data|
              loader.call(tag_id, signature_data)
            end
          end
        end

        def batch_signature_extraction(repository, tag_ids)
          repository.gitaly_ref_client.get_tag_signatures(tag_ids)
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
        @name = encode_utf8_with_escaping!(@raw_tag.name.dup)
        @target = @raw_tag.id
        @message = message_from_gitaly_tag

        if @raw_tag.target_commit.present?
          @target_commit = Gitlab::Git::Commit.decorate(repository, @raw_tag.target_commit)
        end
      end

      def message
        encode! @message
      end

      def user_name
        encode! tagger.name if tagger
      end

      def user_email
        encode! tagger.email if tagger
      end

      def date
        Time.at(tagger.date.seconds).utc if tagger&.date&.seconds
      end

      def has_signature?
        signature_type != :NONE
      end

      def signature_type
        @raw_tag.signature_type || :NONE
      end

      def signature
        return unless has_signature?

        case signature_type
        when :PGP
          nil # not implemented, see https://gitlab.com/gitlab-org/gitlab/issues/19260
        when :X509
          X509::Tag.new(@repository, self).signature
        end
      end

      def cache_key
        "tag:" + Digest::SHA1.hexdigest([name, message, target, target_commit&.sha].join)
      end

      private

      def tagger
        @raw_tag.tagger
      end

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
