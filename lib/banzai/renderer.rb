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
    # markdown - Markdown String
    # context  - Hash of context options passed to our HTML Pipeline
    #
    # Returns an HTML-safe String
    def self.render(text, context = {})
      cache_key = context.delete(:cache_key)
      cache_key = full_cache_key(cache_key, context[:pipeline])

      if cache_key
        Rails.cache.fetch(cache_key) do
          cacheless_render(text, context)
        end
      else
        cacheless_render(text, context)
      end
    end

    def self.render_result(text, context = {})
      Pipeline[context[:pipeline]].call(text, context)
    end

    def self.pre_process(text, context)
      pipeline = Pipeline[:pre_process]

      pipeline.to_html(text, context)
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

    private

    def self.cacheless_render(text, context = {})
      result = render_result(text, context)

      output = result[:output]
      if output.respond_to?(:to_html)
        output.to_html
      else
        output.to_s
      end
    end

    def self.full_cache_key(cache_key, pipeline_name)
      return unless cache_key
      ["banzai", *cache_key, pipeline_name || :full]
    end
  end
end
