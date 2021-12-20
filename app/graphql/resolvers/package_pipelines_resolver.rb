# frozen_string_literal: true

module Resolvers
  class PackagePipelinesResolver < BaseResolver
    include Gitlab::Graphql::Authorize::AuthorizeResource

    type Types::Ci::PipelineType.connection_type, null: true
    extension Gitlab::Graphql::Extensions::ExternallyPaginatedArrayExtension

    authorizes_object!
    authorize :read_pipeline

    alias_method :package, :object

    def resolve(first: nil, last: nil, after: nil, before: nil, lookahead:)
      finder = ::Packages::BuildInfosFinder.new(
        package,
        first: first,
        last: last,
        after: decode_cursor(after),
        before: decode_cursor(before),
        max_page_size: context.schema.default_max_page_size,
        support_next_page: lookahead.selects?(:page_info)
      )

      build_infos = finder.execute

      # this .pluck_pipeline_ids can load max 101 pipelines ids
      ::Ci::Pipeline.id_in(build_infos.pluck_pipeline_ids)
    end

    # we manage the pagination manually, so opt out of the connection field extension
    def self.field_options
      super.merge(
        connection: false,
        extras: [:lookahead]
      )
    end

    private

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
