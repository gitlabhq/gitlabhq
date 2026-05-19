# frozen_string_literal: true

module Banzai
  module Filter
    module References
      # HTML filter that replaces personal snippet references with links.
      #
      # Handles both URL references (e.g. https://gitlab.com/-/snippets/123)
      # and bare text references ($123) for personal snippets.
      #
      # This filter runs after SnippetReferenceFilter in the pipeline, so bare
      # $N references that were already resolved as project snippets will have
      # been replaced with <a> tags and won't be matched here. Only unresolved
      # bare references are picked up as personal snippet candidates.
      class PersonalSnippetReferenceFilter < AbstractReferenceFilter
        self.reference_type = :snippet
        self.object_class = PersonalSnippet

        def call
          return doc unless Feature.enabled?(:personal_snippet_reference_filters, context[:current_user])

          preload_snippets
          super
        end

        def object_sym
          :snippet
        end

        # See AbstractReferenceFilter#object_link_filter, which this overrides.
        # We can't use ReferenceCache since that depends on objects having
        # parents (personal snippets don't), so we instead inquire in our own
        # cache built in preload_snippets.
        def object_link_filter(text, pattern, link_content_html: nil, link_reference: false)
          references_in(text, pattern) do |match_text, id, _project_ref, _namespace_ref, matches|
            snippet = @snippets_by_id[id]
            next unless snippet

            build_object_link(snippet, nil, match_text, matches,
              link_content_html: link_content_html, link_reference: link_reference)
          end
        end

        def url_for_object(snippet, _parent = nil)
          Gitlab::Routing.url_helpers.snippet_url(snippet, only_path: context[:only_path])
        end

        private

        def preload_snippets
          ref_pattern = object_reference_pattern
          link_pattern_anchor = /\A#{PersonalSnippet.link_reference_pattern}\z/
          ids = Set.new

          # Note that this is a very inexact search that can match more than it
          # strictly "needs" to, and it's permitted to be so because we use it
          # only to warm a cache.
          #
          # For similar prior art see:
          #
          # * Banzai::Filter::References::ReferenceCache#load_references_per_parent
          #   (greps across HTML, which we should avoid, but again it's just for
          #   warming a cache and is safe)
          # * Banzai::Filter::References::UserReferenceFilter#usernames
          #   (searches `<a>` hrefs and text node textual contents, like this
          #   one)
          nodes.each do |node|
            if element_node?(node)
              href = node.attr('href').to_s
              next if href.empty?

              match = link_pattern_anchor.match(href)
              ids << match[:snippet].to_i if match
            elsif text_node?(node)
              node.text.scan(ref_pattern) do
                ids << $~[:snippet].to_i
              end
            end
          end

          @snippets_by_id = if ids.any?
                              PersonalSnippet.id_in(ids.to_a).index_by(&:id)
                            else
                              {}
                            end
        end
      end
    end
  end
end
