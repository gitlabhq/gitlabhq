# frozen_string_literal: true

module Resolvers
  class PackagePipelinesResolver < BaseResolver
    include Gitlab::Graphql::Authorize::AuthorizeResource

    type Types::Ci::PipelineType.connection_type, null: true
    extras [:lookahead]

    authorizes_object!
    authorize :read_pipeline

    alias_method :package, :object

    # this resolver can be called for 100 packages max and we want to limit the
    # number of build infos returned for _each_ package when using the new finder.
    MAX_PAGE_SIZE = 20

    # This returns a promise for a connection of promises for pipelines:
    # Lazy[Connection[Lazy[Pipeline]]] structure
    def resolve(lookahead:, first: nil, last: nil, after: nil, before: nil)
      default_value = default_value_for(first: first, last: last, after: after, before: before)
      BatchLoader::GraphQL.for(package.id)
                          .batch(default_value: default_value) do |package_ids, loader|
        build_infos = ::Packages::BuildInfosFinder.new(
          package_ids,
          first: first,
          last: last,
          after: decode_cursor(after),
          before: decode_cursor(before),
          max_page_size: MAX_PAGE_SIZE,
          support_next_page: lookahead.selects?(:page_info)
        ).execute

        build_infos.each do |build_info|
          loader.call(build_info.package_id) do |connection|
            connection.items << lazy_load_pipeline(build_info.pipeline_id)
            connection
          end
        end
      end
    end

    private

    def lazy_load_pipeline(id)
      ::Gitlab::Graphql::Loaders::BatchModelLoader.new(::Ci::Pipeline, id)
        .find
    end

    def default_value_for(first:, last:, after:, before:)
      Gitlab::Graphql::Pagination::ActiveRecordArrayConnection.new(
        [],
        context: context,
        first: first,
        last: last,
        after: after,
        before: before,
        max_page_size: MAX_PAGE_SIZE
      )
    end

    def decode_cursor(encoded)
      return unless encoded

      decoded = Gitlab::Json.parse(context.schema.cursor_encoder.decode(encoded, nonce: true))
      id_from_cursor(decoded)
    rescue JSON::ParserError
      raise Gitlab::Graphql::Errors::ArgumentError, "Please provide a valid cursor"
    end

    def id_from_cursor(cursor)
      cursor&.fetch('id')
    rescue KeyError
      raise Gitlab::Graphql::Errors::ArgumentError, "Please provide a valid cursor"
    end
  end
end
