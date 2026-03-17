# frozen_string_literal: true

class GroupChildSerializer < BaseSerializer
  include WithPagination

  attr_reader :hierarchy_root, :should_expand_hierarchy

  entity GroupChildEntity

  def expand_hierarchy(hierarchy_root = nil)
    @hierarchy_root = hierarchy_root
    @should_expand_hierarchy = true

    self
  end

  # Represents the resource with optional hierarchy expansion.
  #
  # @param resource [ActiveRecord::Relation, Array<GroupDescendant>] The resource(s) to serialize
  # @param opts [Hash] Serialization options
  # @option opts [ActiveRecord::Relation] :pagination_resource Resource for pagination metadata
  #   when different from serialized resource
  # @option opts [Boolean] :upto_preloaded_ancestors_only Limit to preloaded ancestors only
  # @param entity_class [Class, nil] Entity class override
  #
  # @return [Hash, Array<Hash>] Serialized representation of the resource(s)
  def represent(resource, opts = {}, entity_class = nil)
    if should_expand_hierarchy
      # `pagination_resource` allows overriding the object that is used to derive the API pagination headers
      pagination_resource = opts[:pagination_resource] || resource
      paginator.paginate(pagination_resource) if paginated?

      represent_hierarchies(resource, opts)
    else
      super(resource, opts)
    end
  end

  protected

  def represent_hierarchies(children, opts)
    if children.is_a?(GroupDescendant)
      represent_hierarchy(children.hierarchy(hierarchy_root), opts).first
    else
      hierarchies = GroupDescendant.build_hierarchy(children, hierarchy_root, opts)
      # When an array was passed, we always want to represent an array.
      # Even if the hierarchy only contains one element
      represent_hierarchy(Array.wrap(hierarchies), opts)
    end
  end

  def represent_hierarchy(hierarchy, opts)
    serializer = self.class.new(params)

    case hierarchy
    when Hash
      hierarchy.map do |parent, children|
        serializer.represent(parent, opts)
          .merge(children: Array.wrap(serializer.represent_hierarchy(children, opts)))
      end
    when Array
      hierarchy.flat_map { |child| serializer.represent_hierarchy(child, opts) }
    else
      serializer.represent(hierarchy, opts)
    end
  end
end
