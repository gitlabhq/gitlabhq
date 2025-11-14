# frozen_string_literal: true

module Resolvers
  class BlobsResolver < BaseResolver
    include Gitlab::Graphql::Authorize::AuthorizeResource
    include LooksAhead
    include ActiveSupport::NumberHelper
    include Gitlab::Utils::StrongMemoize

    DATA_FIELDS = %i[raw_blob base64_encoded_blob raw_text_blob plain_data].freeze
    TOTAL_BLOB_DATA_SIZE_LIMIT = 20.megabytes
    HUMAN_LIMIT = ActiveSupport::NumberHelper::NumberToHumanSizeConverter.convert(TOTAL_BLOB_DATA_SIZE_LIMIT, {})
    SIZE_LIMIT_EXCEEDED_ERROR = "Max blobs size limit exceeded (%{total} / #{HUMAN_LIMIT}).".freeze

    type Types::Tree::BlobType.connection_type, null: true
    authorize :read_code
    calls_gitaly!

    alias_method :repository, :object

    argument :paths, [GraphQL::Types::String],
      required: true,
      description: 'Array of desired blob paths. ' \
        "When requesting multiple blobs the total size is limited to #{HUMAN_LIMIT}."
    argument :ref, GraphQL::Types::String,
      required: false,
      default_value: nil,
      description: 'Commit ref to get the blobs from. Default value is HEAD.'
    argument :ref_type, Types::RefTypeEnum,
      required: false,
      default_value: nil,
      description: 'Type of ref.'

    # We fetch blobs from Gitaly efficiently but it still scales O(N) with the
    # number of paths being fetched, so apply a scaling limit to that.
    def self.resolver_complexity(args, child_complexity:)
      super + args[:paths].size
    end

    private

    def resolve_with_lookahead(paths:, ref:, ref_type:)
      authorize!(repository.container)

      return [] if repository.empty?

      ref ||= repository.root_ref
      validate_ref!(ref)

      ref_path_pairs = build_ref_path_pairs(paths, ref, ref_type)

      validate_blob_data_size_within_limit!(ref_path_pairs) if validate_blob_data_size?(paths)

      repository.blobs_at(ref_path_pairs).each { |blob| blob.ref_type = ref_type }
    end

    def validate_ref!(ref)
      return if Gitlab::GitRefValidator.validate(ref, skip_head_ref_check: true)

      raise Gitlab::Graphql::Errors::ArgumentError, 'Ref is not valid'
    end

    def build_ref_path_pairs(paths, ref, ref_type)
      qualified_ref = ExtractsRef::RefExtractor.qualify_ref(ref, ref_type)
      paths.map { |path| [qualified_ref, path] }
    end

    def validate_blob_data_size?(paths)
      paths.size > 1 && data_fields_requested?
    end

    def data_fields_requested?
      DATA_FIELDS.intersect?(selected_fields)
    end

    def validate_blob_data_size_within_limit!(ref_path_pairs)
      total_blob_data_size = repository.blobs_at(ref_path_pairs, blob_size_limit: 0).sum(&:size)

      return if total_blob_data_size <= TOTAL_BLOB_DATA_SIZE_LIMIT

      total = number_to_human_size(total_blob_data_size)
      raise Gitlab::Graphql::Errors::ArgumentError, format(SIZE_LIMIT_EXCEEDED_ERROR, total: total)
    end

    def selected_fields
      return [] unless lookahead.present?

      nodes_field_selections | edges_node_field_selections
    end
    strong_memoize_attr :selected_fields

    def nodes_field_selections
      selections_for(:nodes)
    end

    def edges_node_field_selections
      selections_for(:edges, :node)
    end

    def selections_for(*fields)
      fields.inject(lookahead) { |selection, field| selection&.selection(field) }&.selections&.map(&:name) || []
    end
  end
end
