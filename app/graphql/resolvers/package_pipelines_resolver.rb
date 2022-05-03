# frozen_string_literal: true

module Resolvers
  class PackagePipelinesResolver < BaseResolver
    include Gitlab::Graphql::Authorize::AuthorizeResource

    type Types::Ci::PipelineType.connection_type, null: true
    extension Gitlab::Graphql::Extensions::ExternallyPaginatedArrayExtension

    authorizes_object!
    authorize :read_pipeline

    alias_method :package, :object

    # this resolver can be called for 100 packages max and we want to limit the
    # number of build infos returned for _each_ package when using the new finder.
    MAX_PAGE_SIZE = 20

    def resolve(first: nil, last: nil, after: nil, before: nil, lookahead:)
      case detect_mode
      when :object_field
        package.pipelines
      when :new_finder
        resolve_with_new_finder(first: first, last: last, after: after, before: before, lookahead: lookahead)
      else
        resolve_with_old_finder(first: first, last: last, after: after, before: before, lookahead: lookahead)
      end
    end

    # we manage the pagination manually, so opt out of the connection field extension
    def self.field_options
      super.merge(
        connection: false,
        extras: [:lookahead]
      )
    end

    private

    # TODO remove when cleaning up packages_graphql_pipelines_resolver
    # https://gitlab.com/gitlab-org/gitlab/-/issues/358432
    def detect_mode
      return :new_finder if Feature.enabled?(:packages_graphql_pipelines_resolver, default_enabled: :yaml)
      return :object_field if context[:packages_access_level] == :group || context[:packages_access_level] == :project

      :old_finder
    end

    # This returns a promise for a connection of promises for pipelines:
    # Lazy[Connection[Lazy[Pipeline]]] structure
    # TODO rename to #resolve when cleaning up packages_graphql_pipelines_resolver
    # https://gitlab.com/gitlab-org/gitlab/-/issues/358432
    def resolve_with_new_finder(first:, last:, after:, before:, lookahead:)
      default_value = default_value_for(first: first, last: last, after: after, before: before)
      BatchLoader::GraphQL.for(package.id)
                          .batch(default_value: default_value) do |package_ids, loader|
        build_infos = ::Packages::BuildInfosForManyPackagesFinder.new(
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

    def lazy_load_pipeline(id)
      ::Gitlab::Graphql::Loaders::BatchModelLoader.new(::Ci::Pipeline, id)
        .find
    end

    def default_value_for(first:, last:, after:, before:)
      Gitlab::Graphql::Pagination::ActiveRecordArrayConnection.new(
        [],
        first: first,
        last: last,
        after: after,
        before: before,
        max_page_size: MAX_PAGE_SIZE
      )
    end

    # TODO remove when cleaning up packages_graphql_pipelines_resolver
    # https://gitlab.com/gitlab-org/gitlab/-/issues/358432
    def resolve_with_old_finder(first:, last:, after:, before:, lookahead:)
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
