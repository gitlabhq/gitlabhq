# frozen_string_literal: true

module Gitlab
  class SignedTag
    include Gitlab::Utils::StrongMemoize

    class << self
      def from_repository_tag(repository, tag)
        klass = class_for_signature_type(tag.signature_type)
        klass&.new(repository, klass.context_from_tag(tag))
      end

      def class_for_signature_type(signature_type)
        case signature_type
        when :PGP
          Gitlab::Gpg::Tag
        when :X509
          Gitlab::X509::Tag
        when :SSH
          Gitlab::Ssh::Tag
        end
      end

      def context_from_tag(tag)
        {
          user_email: tag.user_email,
          id: tag.id,
          has_signature: tag.has_signature?
        }
      end

      def batch_read_cached_signatures(project, signed_tags)
        signed_tags.group_by(&:signature_class).flat_map do |klass, signed_tags|
          next [] unless klass

          klass.by_project(project).by_object_name(signed_tags.map(&:object_name))
        end
      end

      def batch_write_cached_signatures(signed_tags, timeout: GitalyClient.fast_timeout)
        # caching only supported for repositories of projects
        tags = signed_tags.select { |st| st.repository.container.is_a?(Project) }
        tags.each { |st| st.signature_data(timeout: timeout) }
        new_cached_signatures = tags.filter_map(&:build_cached_signature)
        new_cached_signatures.group_by(&:class).flat_map do |klass, tag_signatures|
          klass.bulk_insert!(tag_signatures)
        end
        new_cached_signatures
      rescue GRPC::DeadlineExceeded
        cache_signatures_async(tags) if timeout < ::Repositories::CacheTagSignaturesWorker::READ_TIMEOUT

        []
      end

      private

      def cache_signatures_async(signed_tags)
        signed_tags.group_by { |st| st.repository.container }.each do |project, sts|
          params = { class_to_context: sts.group_by(&:class).transform_values { |tags| tags.map(&:context) } }
          ::Repositories::CacheTagSignaturesWorker.perform_async(project.id, params)
        end
      end
    end

    def initialize(repository, context)
      @repository = repository
      @context = context
    end

    attr_reader :context, :repository

    def object_name
      @context[:id]
    end

    def signature_data(timeout: GitalyClient.fast_timeout)
      return unless @repository

      @signature_data ||= Gitlab::Git::Tag.extract_signature_lazily(@repository, object_name,
        timeout: timeout)
    end

    def signature; end

    def lazy_cached_signature(timeout: GitalyClient.fast_timeout)
      # caching only supported for repositories of projects
      return unless @repository.container.is_a?(Project)

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
          signed_tag = tags_by_id[tag_signature.object_name].first
          loader.call(signed_tag, tag_signature)
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
