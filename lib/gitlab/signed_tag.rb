# frozen_string_literal: true

module Gitlab
  class SignedTag
    include Gitlab::Utils::StrongMemoize

    class << self
      def batch_read_cached_signatures(project, signed_tags)
        signed_tags.group_by(&:signature_class).flat_map do |klass, signed_tags|
          next [] unless klass

          klass.by_project(project).by_object_name(signed_tags.map(&:object_name))
        end
      end

      def batch_write_cached_signatures(signed_tags, timeout: GitalyClient.fast_timeout)
        signed_tags.each { |st| st.signature_data(timeout: timeout) }
        new_cached_signatures = signed_tags.filter_map(&:build_cached_signature)
        new_cached_signatures.group_by(&:class).flat_map do |klass, tag_signatures|
          klass.bulk_insert!(tag_signatures)
        end
        new_cached_signatures
      end
    end

    def initialize(repository, tag)
      @repository = repository
      @tag = tag
    end

    def object_name
      @tag.id
    end

    def signature_data(timeout: GitalyClient.fast_timeout)
      return unless @repository

      @signature_data ||= Gitlab::Git::Tag.extract_signature_lazily(@repository, object_name,
        timeout: timeout)
    end

    def signature
      return unless @tag.has_signature?
    end

    def lazy_cached_signature(timeout: GitalyClient.fast_timeout)
      BatchLoader.for(self).batch(key: @repository.container.id) do |signed_tags, loader, args|
        tags_by_id = signed_tags.group_by(&:object_name)
        cache_hits = Set.new

        # Read previously cached signatures
        cached_signatures = Gitlab::SignedTag.batch_read_cached_signatures(args[:key], signed_tags)
        cached_signatures.each do |tag_signature|
          cache_hits.add(tag_signature.object_name)
          loader.call(tags_by_id[tag_signature.object_name].first, tag_signature)
        end

        # Write signatures that were previously not cached
        cache_misses = signed_tags.reject { |t| cache_hits.include?(t.object_name) }
        new_cached_signatures = Gitlab::SignedTag.batch_write_cached_signatures(cache_misses,
          timeout: timeout)
        new_cached_signatures.each do |tag_signature|
          loader.call(tags_by_id[tag_signature.object_name].first, tag_signature)
        end
      end
    end

    def signature_class; end

    def build_cached_signature
      attrs = attributes
      return if attrs.nil?

      now = Time.now.utc
      signature_class.new(attrs.merge(created_at: now, updated_at: now))
    end

    def attributes; end

    def signature_text
      signature_data&.fetch(0)
    end

    def signed_text
      signature_data&.fetch(1)
    end
  end
end
