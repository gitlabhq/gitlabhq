# frozen_string_literal: true

module Banzai
  module Filter
    class DiagramProxyPostFilter < HTML::Pipeline::Filter
      prepend Concerns::TimeoutFilterHandler
      prepend Concerns::PipelineTimingCheck
      prepend Concerns::DiagramService

      CSS = '[data-diagram]'
      XPATH = Gitlab::Utils::Nokogiri.css_to_xpath(CSS).freeze

      def call
        return doc unless settings.kroki_diagram_proxy_enabled? || settings.plantuml_diagram_proxy_enabled?

        kroki_formats = ::Gitlab::Kroki.formats(settings)

        doc.xpath(XPATH).each do |node|
          diagram_type = node['data-diagram']
          if diagram_type == 'plantuml'
            next unless settings.plantuml_diagram_proxy_enabled?
          else
            # kroki_formats will be empty if it's disabled.
            next unless kroki_formats.include?(diagram_type)
          end

          begin
            diagram_source = Base64.strict_decode64(node['data-diagram-src'].delete_prefix('data:text/plain;base64,'))
          rescue ArgumentError
            node.remove
            next
          end

          key = self.class.store({
            user_id: context[:current_user]&.id,
            diagram_type: diagram_type,
            diagram_source: diagram_source
          })

          # We're ready to change `node` to point to the diagram proxy.
          #
          # One last check: if it's an <a> created by ImageLinkFilter, which moves the
          # diagram <img>'s data-diagram and data-diagram-src to the new <a> container,
          # we reverse the effect --- the URL is one-time use only so a link is unhelpful.
          # (It's also actively undesirable!)

          if node.name == 'a'
            # We don't need to consider ImageLinkFilter's link_replaces_image option; it's not
            # used in any context where diagrams are permitted.
            img = node.at_css('img')
            img['data-diagram'] = node['data-diagram']
            img['data-diagram-src'] = node['data-diagram-src']
            node.replace(img)
            node = img
          end

          node['src'] = ::Gitlab::Routing.url_helpers.diagram_proxy_url(key: key)

          ImageLazyLoadFilter.apply_lazy_load(node) if node.classes.include?('lazy')
        end

        doc
      end

      class << self
        DIAGRAM_PROXY_PREFIX = 'diagram_proxy'
        DIAGRAM_TTL = 10.minutes

        # Returns the key the data was stored under.
        def store(value)
          key = SecureRandom.uuid

          Gitlab::Redis::Cache.with do |redis|
            redis.set(redis_key(key), value.to_json, ex: DIAGRAM_TTL)
          end

          key
        end

        def getdel(key)
          Gitlab::Redis::Cache.with do |redis|
            redis.getdel(redis_key(key))
          end
        end

        private

        def redis_key(key)
          "#{DIAGRAM_PROXY_PREFIX}:#{key}"
        end
      end
    end
  end
end
