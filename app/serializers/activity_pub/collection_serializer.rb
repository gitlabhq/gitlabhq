# frozen_string_literal: true

module ActivityPub
  # Serializer for the `Collection` ActivityStreams model.
  # Reference: https://www.w3.org/TR/activitystreams-core/#collections
  class CollectionSerializer < ::BaseSerializer
    include WithPagination

    NotPaginatedError = Class.new(StandardError)

    alias_method :base_represent, :represent

    def represent(resources, opts = {})
      unless respond_to?(:paginated?) && paginated?
        raise NotPaginatedError, 'Pass #with_pagination to the serializer or use ActivityPub::ObjectSerializer instead'
      end

      response = if paginator.params['page'].present?
                   represent_page(resources, paginator.params['page'].to_i, opts)
                 else
                   represent_pagination_index(resources)
                 end

      HashWithIndifferentAccess.new(response)
    end

    private

    def represent_page(resources, page, opts)
      resources = paginator.paginate(resources)
      opts[:page] = page
      serialized = base_represent(resources, opts)

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
      paginator.params['page'] = 1
      resources = paginator.paginate(resources)

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
