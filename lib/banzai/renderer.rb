module Banzai
  module Renderer
    # Convert a Markdown String into an HTML-safe String of HTML
    #
    # Note that while the returned HTML will have been sanitized of dangerous
    # HTML, it may post a risk of information leakage if it's not also passed
    # through `post_process`.
    #
    # Also note that the returned String is always HTML, not XHTML. Views
    # requiring XHTML, such as Atom feeds, need to call `post_process` on the
    # result, providing the appropriate `pipeline` option.
    #
    # text     - Markdown String
    # context  - Hash of context options passed to our HTML Pipeline
    #
    # Returns an HTML-safe String
    def self.render(text, context = {})
      cache_key = context.delete(:cache_key)
      cache_key = full_cache_key(cache_key, context[:pipeline])

      if cache_key
        Gitlab::Metrics.measure(:banzai_cached_render) do
          Rails.cache.fetch(cache_key) do
            cacheless_render(text, context)
          end
        end
      else
        cacheless_render(text, context)
      end
    end

    # Convert a Markdown-containing field on an object into an HTML-safe String
    # of HTML. This method is analogous to calling render(object.field), but it
    # can cache the rendered HTML in the object, rather than Redis.
    def self.render_field(object, field, context = {})
      unless object.respond_to?(:cached_markdown_fields)
        return cacheless_render_field(object, field, context)
      end

      object.refresh_markdown_cache! unless object.cached_html_up_to_date?(field)

      object.cached_html_for(field)
    end

    # Same as +render_field+, but without consulting or updating the cache field
    def self.cacheless_render_field(object, field, context = {})
      text = object.__send__(field) # rubocop:disable GitlabSecurity/PublicSend
      context = context.reverse_merge(object.banzai_render_context(field)) if object.respond_to?(:banzai_render_context)

      cacheless_render(text, context)
    end

    # Perform multiple render from an Array of Markdown String into an
    # Array of HTML-safe String of HTML.
    #
    # As the rendered Markdown String can be already cached read all the data
    # from the cache using Rails.cache.read_multi operation. If the Markdown String
    # is not in the cache or it's not cacheable (no cache_key entry is provided in
    # the context) the Markdown String is rendered and stored in the cache so the
    # next render call gets the rendered HTML-safe String from the cache.
    #
    # For further explanation see #render method comments.
    #
    # texts_and_contexts - An Array of Hashes that contains the Markdown String (:text)
    #                      an options passed to our HTML Pipeline (:context)
    #
    # If on the :context you specify a :cache_key entry will be used to retrieve it
    # and cache the result of rendering the Markdown String.
    #
    # Returns an Array containing HTML-safe String instances.
    #
    # Example:
    #    texts_and_contexts
    #    => [{ text: '### Hello',
    #          context: { cache_key: [note, :note] } }]
    def self.cache_collection_render(texts_and_contexts)
      items_collection = texts_and_contexts.each_with_index do |item, index|
        context = item[:context]
        cache_key = full_cache_multi_key(context.delete(:cache_key), context[:pipeline])

        item[:cache_key] = cache_key if cache_key
      end

      cacheable_items, non_cacheable_items = items_collection.partition { |item| item.key?(:cache_key) }

      items_in_cache = []
      items_not_in_cache = []

      unless cacheable_items.empty?
        items_in_cache = Rails.cache.read_multi(*cacheable_items.map { |item| item[:cache_key] })
        items_not_in_cache = cacheable_items.reject do |item|
          item[:rendered] = items_in_cache[item[:cache_key]]
          items_in_cache.key?(item[:cache_key])
        end
      end

      (items_not_in_cache + non_cacheable_items).each do |item|
        item[:rendered] = render(item[:text], item[:context])
        Rails.cache.write(item[:cache_key], item[:rendered]) if item[:cache_key]
      end

      items_collection.map { |item| item[:rendered] }
    end

    def self.render_result(text, context = {})
      text = Pipeline[:pre_process].to_html(text, context) if text

      Pipeline[context[:pipeline]].call(text, context)
    end

    # Perform post-processing on an HTML String
    #
    # This method is used to perform state-dependent changes to a String of
    # HTML, such as removing references that the current user doesn't have
    # permission to make (`RedactorFilter`).
    #
    # html     - String to process
    # context  - Hash of options to customize output
    #            :pipeline  - Symbol pipeline type
    #            :project   - Project
    #            :user      - User object
    #
    # Returns an HTML-safe String
    def self.post_process(html, context)
      context = Pipeline[context[:pipeline]].transform_context(context)

      pipeline = Pipeline[:post_process]
      if context[:xhtml]
        pipeline.to_document(html, context).to_html(save_with: Nokogiri::XML::Node::SaveOptions::AS_XHTML)
      else
        pipeline.to_html(html, context)
      end.html_safe
    end

    def self.cacheless_render(text, context = {})
      return text.to_s unless text.present?

      Gitlab::Metrics.measure(:banzai_cacheless_render) do
        result = render_result(text, context)

        output = result[:output]
        if output.respond_to?(:to_html)
          output.to_html
        else
          output.to_s
        end
      end
    end

    def self.full_cache_key(cache_key, pipeline_name)
      return unless cache_key

      ["banzai", *cache_key, pipeline_name || :full]
    end

    # To map Rails.cache.read_multi results we need to know the Rails.cache.expanded_key.
    # Other option will be to generate stringified keys on our side and don't delegate to Rails.cache.expanded_key
    # method.
    def self.full_cache_multi_key(cache_key, pipeline_name)
      return unless cache_key

      Rails.cache.__send__(:expanded_key, full_cache_key(cache_key, pipeline_name)) # rubocop:disable GitlabSecurity/PublicSend
    end
  end
end
