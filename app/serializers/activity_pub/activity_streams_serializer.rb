# frozen_string_literal: true

module ActivityPub
  class ActivityStreamsSerializer < ::BaseSerializer
    MissingIdentifierError = Class.new(StandardError)
    MissingTypeError = Class.new(StandardError)
    MissingOutboxError = Class.new(StandardError)

    alias_method :base_represent, :represent

    def represent(resource, opts = {}, entity_class = nil)
      response = if respond_to?(:paginated?) && paginated?
                   represent_paginated(resource, opts, entity_class)
                 else
                   represent_whole(resource, opts, entity_class)
                 end

      validate_response(HashWithIndifferentAccess.new(response))
    end

    private

    def validate_response(response)
      unless response[:id].present?
        raise MissingIdentifierError, "The serializer does not provide the mandatory 'id' field."
      end

      unless response[:type].present?
        raise MissingTypeError, "The serializer does not provide the mandatory 'type' field."
      end

      response
    end

    def represent_whole(resource, opts, entity_class)
      raise MissingOutboxError, 'Please provide an :outbox option for this actor' unless opts[:outbox].present?

      serialized = base_represent(resource, opts, entity_class)

      {
        :@context => "https://www.w3.org/ns/activitystreams",
        inbox: opts[:inbox],
        outbox: opts[:outbox]
      }.merge(serialized)
    end

    def represent_paginated(resources, opts, entity_class)
      if paginator.params['page'].present?
        represent_page(resources, resources.current_page, opts, entity_class)
      else
        represent_pagination_index(resources)
      end
    end

    def represent_page(resources, page, opts, entity_class)
      opts[:page] = page
      serialized = base_represent(resources, opts, entity_class)

      {
        :@context => 'https://www.w3.org/ns/activitystreams',
        type: 'OrderedCollectionPage',
        id: collection_url(page),
        prev: page > 1 ? collection_url(page - 1) : nil,
        next: page < resources.total_pages ? collection_url(page + 1) : nil,
        partOf: collection_url,
        orderedItems: serialized
      }
    end

    def represent_pagination_index(resources)
      {
        :@context => 'https://www.w3.org/ns/activitystreams',
        type: 'OrderedCollection',
        id: collection_url,
        totalItems: resources.total_count,
        first: collection_url(1),
        last: collection_url(resources.total_pages)
      }
    end

    def collection_url(page = nil)
      uri = URI.parse(paginator.request.url)
      uri.query ||= ""
      parts = uri.query.split('&').reject { |part| part =~ /^page=/ }
      parts << "page=#{page}" if page
      uri.query = parts.join('&')
      uri.to_s.sub(/\?$/, '')
    end
  end
end
